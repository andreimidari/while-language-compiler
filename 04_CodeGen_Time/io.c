#include "stdio.h"
#include <string.h>

unsigned read_unsigned()
{
	unsigned ret = 0;
	if( fscanf( stdin, "%u", &ret ) != 1 )
		return 0;
	return ret;
}

int read_signed()
{
	int ret = 0;
	if( fscanf( stdin, "%d", &ret ) != 1 )
		return 0;
	return ret;
}

int read_boolean()
{
	char ret[256] = "";
	if( fscanf( stdin, "%255s", ret ) != 1 )
		return 0;
	return !strcmp(ret,"true");
}

void write_unsigned( unsigned num )
{
	fprintf( stdout, "%u\n", num );
}

void write_signed( int num )
{
	fprintf( stdout, "%d\n", num );
}

void write_boolean( int num )
{
	if( num )
		fprintf( stdout, "true\n" );
	else
		fprintf( stdout, "false\n" );
}
