import core.stdc.stdlib : exit, EXIT_SUCCESS;
import std.stdio;
import std.string : chomp;

void printPrompt()
{
	write("db > ");
}

void main()
{
	while (true)
	{
		printPrompt();
		string line = stdin.readln.chomp;
		if (line == ".exit")
		{
			exit(EXIT_SUCCESS);
		}
		else
		{
			writefln("Unrecognized command '%s'.", line);
		}
	}
}
