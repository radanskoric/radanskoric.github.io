---
layout: post
title: "Coding agent in 94 lines of Ruby"
date: 2025-05-14
categories: articles
tags: ruby ai llm coding-agent
---

> "It’s not that hard to build a fully functioning, code-editing agent."
>
> *Thorsten Ball*

An article floated into my reading list: [How to Build an Agent, or: The Emperor Has No Clothes](https://ampcode.com/how-to-build-an-agent){:target="_blank"}. The author, Thorsten Ball, claims building a coding agent isn't hard, then builds one in ~400 lines of Go. While reading the code, I kept thinking that a lot of it is boilerplate. My *keen* suspicion received confirmation when the author wrote: *"... most of which is boilerplate"*.

Boilerplate? Ruby excels at eliminating boilerplate, leaving just the essence. I thought: creating this in Ruby must be even more straightforward. So I tried it. And straightforward it was!

Doing the exercise in Ruby gave me two interesting realisations which I'll share at the end of the article.

The good news is that the end of this article really isn't far because of how straightforward the agent was! This is some top notch drama here.

> Interested in trying out the final agent? Find the full code on GitHub: [radanskoric/coding_agent](https://github.com/radanskoric/coding_agent){:target="_blank"}. It includes a handy one-line command for building and running it through Docker.
{: .prompt-tip }

## Building the agent

A coding agent, stripped to its bones, is simply an AI chat agent with **tool** access.

Most modern LLMs, especially those from large vendors, can use **tools**. Under the hood, tools are simply functions with descriptions of their purpose and expected parameters, formatted in LLM-recognizable ways.

The basis of an AI chat agent is a chat loop:
1. Read a user prompt.
2. Feed the prompt to the LLM.
3. Print the LLM response to the user.
4. Repeat until the user finds something better to do.

To make it an agent, you give it some tools. It turns out that for a very simple coding agent you need just 3 tools:
1. **Read file:** given a file, return the content of the file.
2. **List files**: given a directory, return a list of files in the directory.
3. **Edit file:** given a file, original string and new string, update the file by replacing the original with new string.

Remarkably, adding just these 3 tools to an LLM-connected chat loop transforms the program into a coding agent capable of building your next startup.[^1]

Let's dive into the code.

### The chat loop

We'll use the [RubyLLM](https://rubyllm.com/){:target="_blank"} gem. Our usage will be so simple other gems would work as well, but I like its delightfully clean interface.

It's very easy to configure:
```ruby
require "ruby_llm"

RubyLLM.configure do |config|
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", nil)
  config.default_model = "claude-3-7-sonnet"
end
```
{: file="run.rb"}

I'll use Anthropic, but to follow along with a different provider, simply change the configuration. The gem [supports most providers](https://rubyllm.com/configuration#global-configuration-rubyllmconfigure){:target="_blank"}.

We'll encapsulate the loop in an `Agent` class with a single `run` method that we'll call from the main method:
```ruby
require "ruby_llm"

class Agent
  def initialize
    @chat = RubyLLM.chat
  end

  def run
    puts "Chat with the agent. Type 'exit' to ... well, exit"
    loop do
      print "> "
      user_input = gets.chomp
      break if user_input == "exit"

      response = @chat.ask user_input
      puts response.content
    end
  end
end
```
{: file="src/agent.rb"}

Then call it from the main `run.rb` file:

```ruby
require_relative "src/agent"
Agent.new.run
```
{: file="run.rb"}

At this point, this very short program works like a regular AI chat: you can talk to it just like any other AI chat.

> LLM chats don't keep conversation history. They simulate continuous conversation by sending the full transcript with each new message.
>
>The RubyLLM gem handles this automatically, so we don't need to worry about it.
{: .prompt-info }

Next step: give it the ability to do more than just chat to us.

### Read file tool

First, let's implement a read file tool. RubyLLM implements tools as Ruby classes with structured tool descriptions and a single `execute` method for the tool functionality:

```ruby
require "ruby_llm/tool"

module Tools
  class ReadFile < RubyLLM::Tool
    description "Read the contents of a given relative file path. Use this when you want to see what's inside a file. Do not use this with directory names."
    param :path, desc: "The relative path of a file in the working directory."

    def execute(path:)
      File.read(path)
    rescue => e
      { error: e.message }
    end
  end
end
```
{: file="src/tools/read_file.rb"}

The actual tool implementation contains just one line: `File.read(path)`. The rest describes the tool for the LLM so it "knows" when to call it.

We also capture file reading errors and return them to the LLM. If you feed the error back to the LLM it can often recover on its own from simple errors like *missing file*.

Finally, tell our chat object in the `Agent` class to use the tool:
```ruby
require_relative "tools/read_file"

class Agent
  def initialize
    @chat = RubyLLM.chat
    @chat.with_tools(Tools::ReadFile)
  end

  # ...
end
```

Try it out! The chat agent can now read specific files to answer questions:
```shell
$ ruby run.rb
Chat with the agent. Type 'exit' to ... well, exit
> What is the name of the first gem declared in Gemfile?
The name of the first gem declared in the Gemfile is "ruby_llm".
>
```

#### How does the LLM know about the tools?

*This little digression explains how tools work. Skip to the [next section](#list-files-tool) if you're not interested.*

The tool description and parameters transform into a JSON structure that is sent to the LLM alongside the conversation transcript. Each time the LLM composes an answer, it receives everything needed to do its job.

The tool-describing JSON structure follows a specific format, varying between providers. The gem abstracts these differences away. When the LLM calls the tool, it returns a formatted response. The gem recognizes this format, translates it to a **tool instance method call**, and passes the response back to the LLM.

For the previous example, this is the tool declaration that is sent to Claude for our Read file tool:
```json
{
  "name": "tools--read_file",
  "description": "Read the contents of a given relative file path. Use this when you want to see what's inside a file. Do not use this with directory names.",
  "input_schema": {
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "The relative path of a file in the working directory."
      }
    },
    "required": [
      "path"
    ]
  }
}
```

This is the message that Claude sends back:
```json
[
  {
    "type": "text",
    "text": "I'll check the Gemfile to find the name of the first gem declared in it."
  },
  {
    "type": "tool_use",
    "id": "toolu_01C5m4yKNyqhsyKehhtstnLA",
    "name": "tools--read_file",
    "input": {
      "path": "Gemfile"
    }
  }
]
```

And this is the formatted response from the tool we just implemented:
```json
{
  "type": "tool_result",
  "tool_use_id": "toolu_01C5m4yKNyqhsyKehhtstnLA",
  "content": "source \"https://rubygems.org\"\n\ngem \"ruby_llm\"\ngem \"dotenv\"\n\ngroup :development, :test do\n  gem \"debug\"\n  gem \"minitest\"\nend\n"
}
```

Notice the ids matching.

Claude is trained to recognise the tool format and to respond in a specific format. The gem translates between the JSON format and a plain Ruby method call on the tool object.

### List files tool {#list-files-tool}

Next step: allow the agent to list files!

When given a directory path, the tool returns an array of filenames inside that directory. The LLM needs to distinguish between files and directories. We'll append `/` to directory names. I took this from the original article. Normally you would experiment to find the most effective format.

```ruby
require "ruby_llm/tool"

module Tools
  class ListFiles < RubyLLM::Tool
    description "List files and directories at a given path. If no path is provided, lists files in the current directory."
    param :path, desc: "Optional relative path to list files from. Defaults to current directory if not provided."

    def execute(path: "")
      Dir.glob(File.join(path, "*"))
         .map { |filename| File.directory?(filename) ? "#{filename}/" : filename }
    rescue => e
      { error: e.message }
    end
  end
end
```
{: file="src/tools/list_files.rb"}

The tool follows the same pattern as the Read file tool. Add it to the chat:

```ruby
require_relative "tools/list_files"
#...
@chat.with_tools(Tools::ReadFile, Tools::ListFiles)
```
{: file="src/agent.rb"}

Try the chat now to ask various questions about your existing files. It will be able to list and read them. It still can't modify files yet.

### Edit file tool

The tool that will finally turn it into a proper coding agent is the edit file tool.

This interface is more complex than the others. It takes 3 parameters: file path, old string, and new string. The LLM edits files by repeatedly telling the tool to replace strings. Most importantly, if there's no path matching the file the tool creates a new file. This allows the LLM to write new files by passing a fresh path and setting the old string to `""`.

I also took this approach from the original article. It works especially well with Claude. Again, you would discover that on your own by experimenting.

```ruby
require "ruby_llm/tool"

module Tools
  class EditFile < RubyLLM::Tool
    description <<~DESCRIPTION
      Make edits to a text file.

      Replaces 'old_str' with 'new_str' in the given file.
      'old_str' and 'new_str' MUST be different from each other.

      If the file specified with path doesn't exist, it will be created.
    DESCRIPTION
    param :path, desc: "The path to the file"
    param :old_str, desc: "Text to search for - must match exactly and must only have one match exactly"
    param :new_str, desc: "Text to replace old_str with"

    def execute(path:, old_str:, new_str:)
      content = File.exist?(path) ? File.read(path) : ""
      File.write(path, content.sub(old_str, new_str))
    rescue => e
      { error: e.message }
    end
  end
end
```
{: file="src/tools/edit_file.rb"}

Add it to the list of tools:
```ruby
require "tools/edit_file"
# ...
@chat.with_tools(Tools::ReadFile, Tools::ListFiles, Tools::EditFile)
```
{: file="src/agent.rb"}

And with that, we have an agent! Let's test it.

## Testing the agent

For testing, I asked it to implement ASCII Minesweeper in Ruby, an exercise I previously wrote about in ["Minesweeper in 100 lines of clean Ruby"](/experiments/minesweeper-100-lines-of-clean-ruby).

To my surprise the agent one-shot this. It used 135 lines instead of my 100, and I'd argue my code is much better, but the game works! Check out the output and full prompt in this [gist](https://gist.github.com/radanskoric/3609d411cbc035eaaaaf314eb6c4cd9a){:target="_blank"} to judge for yourself.

However, the tests it wrote don't work - they have two failures. But cut the agent some slack! It had to dry code the tests without running them.

## Improving the agent

At this point, we've matched the original article's functionality with just 75 lines of Ruby. With room to spare, let's improve it by adding another tool.

### Execute shell commands tool

Until now, the agent could only dry code. By giving it command-running abilities, I hope it will test its own code and iterate on it.

To avoid it going all [Skynet](https://xkcd.com/1046/){:target="_blank"} on me, I won't let it execute commands independently. Instead, we'll ask for user confirmation before running any command.

```ruby
require "ruby_llm/tool"

module Tools
  class RunShellCommand < RubyLLM::Tool
    description "Execute a linux shell command"
    param :command, desc: "The command to execute"

    def execute(command:)
      puts "AI wants to execute the following shell command: '#{command}'"
      print "Do you want to execute it? (y/n) "
      response = gets.chomp
      return { error: "User declined to execute the command" } unless response == "y"

      `#{command}`
    rescue => e
      { error: e.message }
    end
  end
end
```
{: file="src/tools/run_shell_command.rb" }

Add it to the list of tools:
```ruby
require "tools/run_shell_command"
# ...
@chat.with_tools(Tools::ReadFile, Tools::ListFiles, Tools::EditFile, Tools::RunShellCommand)
```

Here's an example of the agent using it to get the today's date:
```
Chat with the agent. Type 'exit' to ... well, exit
> What date is today?
AI wants to execute the following shell command: 'date'
Do you want to execute it? (y/n) y
Today's date is Wednesday, May 14, 2025 (UTC time).
>
```

With that our little agent is complete at a total of 94 lines of Ruby!

### Testing the improved agent

I ran it again with the same [minesweeper prompt](https://gist.github.com/radanskoric/3609d411cbc035eaaaaf314eb6c4cd9a#file-prompt-md){:target="_blank"}, adding only *"Make sure that tests pass."* to the end.

This time the agent worked much longer, asking me to run shell commands 10 times. It created a more comprehensive 191-line Ruby implementation, even adding mine flagging I never requested[^2].

And the tests work this time! Probably because it asked me 6 times to run them.

Interested in what it generated? It's in this GitHub repo: [radanskoric/coding_agent_minesweeper_test](https://github.com/radanskoric/coding_agent_minesweeper_test){:target="_blank"}.

## Takeaways

There are two main takeaways for me:
1. Building a coding agent requires almost no specialist AI skills. It's mostly just regular software development. Also, notice I improved on the original article's agent by adding another tool. I didn't use any AI engineering knowledge for this. Instead, my extensive experience testing my own broken code told me this should make a difference. Not exactly rocket surgery.
2. Ruby is really well suited for this. The RubyLLM gem's excellent boilerplate elimination isn't accidental. First of all: Ruby is built for programmer happiness. Secondly: the Ruby community highly values readability. This is the norm in Ruby.

So, if you have a coding agent idea, there's nothing preventing you from experimenting. The coding agent from this article is available at [https://github.com/radanskoric/coding_agent](https://github.com/radanskoric/coding_agent){:target="_blank"} under the permissive MIT license. It would make me very happy if you forked it.

## Footnotes

[^1]: Yes, I'm exaggerating, but not about this being a coding agent. The startup-building claim is the exaggeration.

[^2]: The fact that it went out on its own without me asking is an issue by itself, but let's ignore it now since that's a general LLMs issue.


