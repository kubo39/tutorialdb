import std.process;
import std.stdio;

string[] runScript(string[] commands)
{
    auto pipes = pipeProcess(["./tutorialdb"]);
    scope(exit) wait(pipes.pid);
    foreach (command; commands)
    {
        pipes.stdin.writeln(command);
    }
    pipes.stdin.flush();

    string[] output;
    foreach (line; pipes.stdout.byLine)
    {
        output ~= line.idup;
    }
    return output;
}

void main()
{
    auto result = runScript([
        "insert 1 user1 person1@example.com",
        "select",
        ".exit"
    ]);
    assert(result == [
        "db > Executed.",
        "db > (1, user1, person1@example.com)",
        "Executed.",
        "db > "
    ]);
}
