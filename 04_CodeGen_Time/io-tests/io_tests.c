#define _POSIX_C_SOURCE 200809L

#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

unsigned read_unsigned(void);
int read_signed(void);
int read_boolean(void);
void write_unsigned(unsigned num);
void write_signed(int num);
void write_boolean(int num);

static int failures;

static void check(int condition, const char *what)
{
	if (condition) {
		printf("ok - %s\n", what);
	} else {
		printf("FAIL - %s\n", what);
		failures++;
	}
}

/* Replace stdin with an in-memory file containing text. */
static void feed(const char *text)
{
	FILE *input = tmpfile();
	fputs(text, input);
	rewind(input);
	clearerr(stdin);
	if (dup2(fileno(input), fileno(stdin)) < 0) {
		perror("dup2");
		failures++;
	}
	fclose(input);
}

/* Replace stdin with count copies of fill followed by a newline. */
static void feed_long(int count, int fill)
{
	FILE *input = tmpfile();
	int i;
	for (i = 0; i < count; i++)
		fputc(fill, input);
	fputc('\n', input);
	rewind(input);
	clearerr(stdin);
	if (dup2(fileno(input), fileno(stdin)) < 0) {
		perror("dup2");
		failures++;
	}
	fclose(input);
}

/* Capture everything a writer function sends to stdout. */
static char *capture(void (*writer)(void *), void *argument)
{
	static char buffer[256];
	FILE *output;
	int saved;
	size_t length;

	fflush(stdout);
	output = tmpfile();
	saved = dup(fileno(stdout));
	dup2(fileno(output), fileno(stdout));

	writer(argument);
	fflush(stdout);

	dup2(saved, fileno(stdout));
	close(saved);

	rewind(output);
	length = fread(buffer, 1, sizeof(buffer) - 1, output);
	buffer[length] = '\0';
	fclose(output);
	return buffer;
}

static void write_unsigned_zero(void *unused)
{
	(void)unused;
	write_unsigned(0);
}

static void write_unsigned_max(void *unused)
{
	(void)unused;
	write_unsigned(4294967295u);
}

static void write_signed_minus_one(void *unused)
{
	(void)unused;
	write_signed(-1);
}

static void write_signed_min(void *unused)
{
	(void)unused;
	write_signed(INT_MIN);
}

static void write_boolean_zero(void *unused)
{
	(void)unused;
	write_boolean(0);
}

static void write_boolean_one(void *unused)
{
	(void)unused;
	write_boolean(1);
}

static void write_boolean_two(void *unused)
{
	(void)unused;
	write_boolean(2);
}

static void write_boolean_minus_one(void *unused)
{
	(void)unused;
	write_boolean(-1);
}

int main(void)
{
	/* Keep stdin unbuffered so replacing fd 0 between cases is safe. */
	setvbuf(stdin, NULL, _IONBF, 0);

	check(strcmp(capture(write_unsigned_zero, NULL), "0\n") == 0,
	      "write_unsigned(0)");
	check(strcmp(capture(write_unsigned_max, NULL), "4294967295\n") == 0,
	      "write_unsigned(4294967295)");
	check(strcmp(capture(write_signed_minus_one, NULL), "-1\n") == 0,
	      "write_signed(-1)");
	check(strcmp(capture(write_signed_min, NULL), "-2147483648\n") == 0,
	      "write_signed(INT_MIN)");
	check(strcmp(capture(write_boolean_zero, NULL), "false\n") == 0,
	      "write_boolean(0)");
	check(strcmp(capture(write_boolean_one, NULL), "true\n") == 0,
	      "write_boolean(1)");
	check(strcmp(capture(write_boolean_two, NULL), "true\n") == 0,
	      "write_boolean(2)");
	check(strcmp(capture(write_boolean_minus_one, NULL), "true\n") == 0,
	      "write_boolean(-1)");

	feed("0\n");
	check(read_unsigned() == 0u, "read_unsigned(0)");
	feed("42\n");
	check(read_unsigned() == 42u, "read_unsigned(42)");
	feed("4294967295\n");
	check(read_unsigned() == 4294967295u, "read_unsigned(4294967295)");
	feed("");
	check(read_unsigned() == 0u, "read_unsigned at EOF returns 0");

	feed("0\n");
	check(read_signed() == 0, "read_signed(0)");
	feed("42\n");
	check(read_signed() == 42, "read_signed(42)");
	feed("-7\n");
	check(read_signed() == -7, "read_signed(-7)");
	feed("2147483647\n");
	check(read_signed() == INT_MAX, "read_signed(INT_MAX)");
	feed("-2147483648\n");
	check(read_signed() == INT_MIN, "read_signed(INT_MIN)");
	feed("");
	check(read_signed() == 0, "read_signed at EOF returns 0");

	feed("true\n");
	check(read_boolean() == 1, "read_boolean(true)");
	feed("false\n");
	check(read_boolean() == 0, "read_boolean(false)");
	feed("TRUE\n");
	check(read_boolean() == 0, "read_boolean(TRUE) is false");
	feed("1\n");
	check(read_boolean() == 0, "read_boolean(1) is false");
	feed("tru\n");
	check(read_boolean() == 0, "read_boolean(tru) is false");
	feed("");
	check(read_boolean() == 0, "read_boolean at EOF returns 0");

	feed_long(300, 'x');
	check(read_boolean() == 0, "read_boolean handles a 300-character token");

	if (failures != 0) {
		printf("%d io test(s) failed\n", failures);
		return 1;
	}
	printf("all io tests passed\n");
	return 0;
}
