import core.stdc.stdlib : exit, EXIT_SUCCESS;
import std.stdio;
import std.string : chomp, startsWith;

void printPrompt()
{
	write("db > ");
}

enum MetaCommandResult
{
	SUCCESS,
	UNRECOGNIZED_COMMAND
}

MetaCommandResult doMetaCommand(string input)
{
	if (input == ".exit")
		exit(EXIT_SUCCESS);
	else
		return MetaCommandResult.UNRECOGNIZED_COMMAND;
}

enum PrepareResult
{
	SUCCESS,
	UNRECOGNIZED_STATEMENT
}

enum StatementType
{
	INSERT,
	SELECT
}

struct Statement
{
	StatementType type;
}

PrepareResult prepareStatement(string input, ref Statement statement)
{
	if (input == "insert")
	{
		statement.type = StatementType.INSERT;
		return PrepareResult.SUCCESS;
	}
	else if (input == "select")
	{
		statement.type = StatementType.SELECT;
		return PrepareResult.SUCCESS;
	}
	return PrepareResult.UNRECOGNIZED_STATEMENT;
}

void executeStatement(const Statement statement)
{
	final switch (statement.type)
	{
	case StatementType.INSERT:
		writeln("This is where we would do an insert.");
		break;
	case StatementType.SELECT:
		writeln("This is where we would do an select.");
		break;
	}
}

void main()
{
	while (true)
	{
		printPrompt();

		string input = stdin.readln.chomp;

		// handle meta-commands.
		if (input.startsWith('.'))
		{
			final switch (doMetaCommand(input))
			{
			case MetaCommandResult.SUCCESS:
				continue;
			case MetaCommandResult.UNRECOGNIZED_COMMAND:
				writefln("Unrecognized command '%s'.", input);
				continue;
			}
		}

		Statement statement;
		final switch (prepareStatement(input, statement))
		{
		case PrepareResult.SUCCESS:
			break;
		case PrepareResult.UNRECOGNIZED_STATEMENT:
			writefln("Unrecognized keyword at start of '%s'.", input);
			continue;
		}

		executeStatement(statement);
		writeln("Executed.");
	}
}
