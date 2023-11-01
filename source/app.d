import core.stdc.stdlib : exit, EXIT_SUCCESS, free, malloc;
import core.stdc.string : memcpy, strcpy;

import std.format : formattedRead;
import std.stdio;
import std.string : chomp, startsWith, toStringz;

enum uint PAGE_SIZE = 4096;
enum uint TABLE_MAX_PAGES = 100;
enum uint ROWS_PER_PAGE = PAGE_SIZE / TABLE_MAX_PAGES;
enum uint TABLE_MAX_ROWS = ROWS_PER_PAGE * TABLE_MAX_PAGES;

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
	UNRECOGNIZED_STATEMENT,
	SYNTAX_ERROR
}

enum StatementType
{
	INSERT,
	SELECT
}

enum COLUMN_USERNAME_SIZE = 32;
enum COLUMN_EMAIL_SIZE = 255;

static assert(Row.id.sizeof == 4);
enum ID_SIZE = Row.id.sizeof;
static assert(Row.username.sizeof == 32);
enum USERNAME_SIZE = Row.username.sizeof;
static assert(Row.email.sizeof == 255);
enum EMAIL_SIZE = Row.email.sizeof;
static assert(Row.id.offsetof == 0);
enum ID_OFFSET = Row.id.offsetof;
static assert(Row.username.offsetof == 4);
enum USERNAME_OFFSET = Row.username.offsetof;
static assert(Row.email.offsetof == 36);
enum EMAIL_OFFSET = Row.email.offsetof;
static assert(Row.sizeof == 291);
enum ROW_SIZE = Row.sizeof;

struct Row
{
align(1):
	uint id;
	char[COLUMN_USERNAME_SIZE] username;
	char[COLUMN_EMAIL_SIZE] email;
}

void serializeRow(const(Row)* source, void* destination)
{
	memcpy(destination + ID_OFFSET, &source.id, ID_SIZE);
	memcpy(destination + USERNAME_OFFSET, &source.username, USERNAME_SIZE);
	memcpy(destination + EMAIL_OFFSET, &source.email, EMAIL_SIZE);
}

void desrializeRow(void* source, Row* destination)
{
	memcpy(&destination.id, source + ID_OFFSET, ID_SIZE);
	memcpy(&destination.username, source + USERNAME_OFFSET, USERNAME_SIZE);
	memcpy(&destination.email, source + EMAIL_OFFSET, EMAIL_SIZE);
}

struct Statement
{
	StatementType type;
	Row rowToInsert;
}

PrepareResult prepareStatement(string input, ref Statement statement)
{
	if (input.startsWith("insert"))
	{
		statement.type = StatementType.INSERT;
		string username, email;
		auto argsAssinged = formattedRead(
			input[6..$], " %d %s %s",
			statement.rowToInsert.id,
			username,
			email
		);

		strcpy(&statement.rowToInsert.username[0], cast(const)(username ~ '\0').dup.ptr);
		strcpy(&statement.rowToInsert.email[0], cast(const)(email ~ '\0').dup.ptr);
		if (argsAssinged < 3)
			return PrepareResult.SYNTAX_ERROR;
		return PrepareResult.SUCCESS;
	}
	else if (input.startsWith("select"))
	{
		statement.type = StatementType.SELECT;
		return PrepareResult.SUCCESS;
	}
	return PrepareResult.UNRECOGNIZED_STATEMENT;
}

enum ExecuteResult
{
	SUCCESS,
	TABLE_FULL
}

ExecuteResult executeInsert(Statement* statement, Table* table)
{
	writeln("executeInsert.");
	if (table.numRows >= TABLE_MAX_ROWS)
		return ExecuteResult.TABLE_FULL;

	const(Row)* rowToInsert = &statement.rowToInsert;

	serializeRow(rowToInsert, rowSlot(table, table.numRows));
	table.numRows++;

	return ExecuteResult.SUCCESS;
}

void printRow(const(Row)* row)
{
	writefln!"(%d %s %s)"(row.id, row.username, row.email);
}

ExecuteResult executeSelect(Statement* statement, Table* table)
{
	Row row;
	foreach (i; 0..table.numRows)
	{
		desrializeRow(rowSlot(table, i), &row);
		printRow(&row);
	}
	return ExecuteResult.SUCCESS;
}

ExecuteResult executeStatement(Statement* statement, Table* table)
{
	final switch (statement.type)
	{
	case StatementType.INSERT:
		return executeInsert(statement, table);
	case StatementType.SELECT:
		return executeSelect(statement, table);
	}
}

struct Table
{
	uint numRows;
	void*[TABLE_MAX_PAGES] pages;
}

Table* newTable()
{
	Table* table = cast(Table*) malloc(Table.sizeof);
	table.numRows = 0;
	foreach (i; 0..TABLE_MAX_PAGES)
	{
		table.pages[i] = null;
	}
	return table;
}

void freeTable(Table* table)
{
	foreach (i; 0..TABLE_MAX_PAGES)
	{
		free(table.pages[i]);
	}
	free(table);
}

void* rowSlot(Table* table, uint rowNum)
{
	uint pageNum = rowNum / ROWS_PER_PAGE;
	void* page = table.pages[pageNum];
	if (page is null)
	{
		// Allocate memory only when we try to access page.
		page = table.pages[pageNum] = malloc(PAGE_SIZE);
	}
	uint rowOffset = rowNum % ROWS_PER_PAGE;
	uint byteOffset = cast(uint) (rowOffset * ROW_SIZE);
	return page + byteOffset;
}

void main()
{
	Table* table = newTable();
	scope(exit) freeTable(table);

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
		case PrepareResult.SYNTAX_ERROR:
			writeln("Syntax error. Could not parse statement.");
			continue;
		}

		final switch (executeStatement(&statement, table))
		{
		case ExecuteResult.SUCCESS:
			writeln("Executed.");
			break;
		case ExecuteResult.TABLE_FULL:
			writeln("Error: Table full.");
			break;
		}
	}
}
