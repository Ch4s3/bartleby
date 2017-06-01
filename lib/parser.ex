defmodule Parser do
  @moduledoc """
  The parser takes a file_name as an argument and converts it to an AST using
  `Code.string_to_quoted!`. It then parses the ast and builds a struct representing
  the test file and its tags, cases, and assertions.
  ##Examples
    iex> Parser.parse("test/fixtures/phoenix_controller_test.txt")
    %TestFile{name: "PhoenixControllerTest"}
  """
  @spec parse(String.t) :: TestFile.t
  def parse(file_name) do
    with {:ok, file} <- File.read(file_name),
         {:ok, ast} <- Code.string_to_quoted(file),
         {:ok, nodes} <- get_nodes(ast) do
      # ast
      # |> get_nodes
      # |> Enum.map(&node_name/1)

      %TestFile{
       name: name(ast),
       docs: get_docs(nodes)
      }
    else {:error, error} ->
      error
    end
  end

  def name({:defmodule, _, module_line}) do
    module_line
    |> Enum.at(0)
    |> get_module_name
  end

  def get_module_name({:__aliases__, _line, [name]}) do
    name |> Atom.to_string
  end

  def get_docs(nodes) do
    nodes
    |> Enum.find(fn n -> _is_doc_node?(n) end)
    |> Tuple.to_list
    |> Enum.at(2)
    |> Enum.at(0)
    |> Tuple.to_list
    |> Enum.at(2)
    |> Enum.at(0)
  end

  def get_nodes(ast) do
    {_def, _l, rest} = ast
    body = rest |> Enum.at(1) |> Enum.at(0)
    {_do, {_block, _some_other_thing, nodes}} = body
    {:ok, nodes}
  end

  def node_name({:@, _line_number, content}) do
    IO.inspect Enum.at(content, 0)
  end

  defp _is_doc_node?({:@, _l, [{:moduledoc, _l2, [_text]}]}) do
    true
  end
  defp _is_doc_node?(_), do: false

  def node_name({:test, _line_number, content}) do
    IO.puts(Enum.at(content, 0))
    get_assertions(content)
  end
  def node_name(_node_content), do: ""

  def get_assertions([_name, [{_do, {_block, _meta, nodes}}]]) do
    get_assertions(nodes)
  end

  def get_assertions(nodes) do
    nodes
    |> Enum.map(&print_assertion/1)
  end
  def get_assertions(nil), do: ""

  def print_assertion({:assert, _line, _content} = node) do
    IO.puts(Macro.to_string(node))
  end
  def print_assertion({:refute, _line, _content} = node) do
    IO.puts(Macro.to_string(node))
  end
  def print_assertion(_), do: ""
end
