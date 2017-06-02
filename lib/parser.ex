defmodule Parser do
  @moduledoc """
  The parser takes a file_name as an argument and converts it to an AST using
  `Code.string_to_quoted!`. It then parses the ast and builds a struct representing
  the test file and its tags, cases, and assertions.
  ##Examples
    iex> Parser.parse("test/fixtures/phoenix_controller_test.txt")
    %TestFile{docs: "For test purposes, here are the docs\\nsome more lines\\n",
            module_tags: [], name: "PhoenixControllerTest",
            test_cases: [
              %TestCase{
                assertions: [
                  "assert(response.status() == 200)",
                  "assert(String.contains?(response.resp_body(), expectation_1))"],
                name: "#POST /api/v1/the_apt returns proper response",
                refutations: []
              }
            ]
          }
  """
  @spec parse(String.t) :: TestFile.t
  def parse(file_name) do
    with {:ok, file} <- File.read(file_name),
         {:ok, ast} <- Code.string_to_quoted(file),
         {:ok, nodes} <- get_nodes(ast) do

      %TestFile{
       name: name(ast),
       docs: get_docs(nodes),
       test_cases: get_test_cases(nodes)
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

  def get_test_cases(nodes) do
    nodes
    |> Enum.map(&build_test_case/1)
    |> Enum.filter(&is_map/1)
  end

  def get_nodes(ast) do
    {_def, _l, rest} = ast
    body = rest |> Enum.at(1) |> Enum.at(0)
    {_do, {_block, _meta_data, nodes}} = body
    {:ok, nodes}
  end

  defp _is_doc_node?({:@, _l, [{:moduledoc, _l2, [_text]}]}) do
    true
  end
  defp _is_doc_node?(_), do: false

  def build_test_case({:test, _line, test}) do
    %TestCase{
      name: Enum.at(test, 0),
      assertions: get_assertions(test),
      refutations: get_refutations(test)
    }
  end
  def build_test_case(_), do: nil

  def get_assertions([_name, [{_do, {_block, _meta, nodes}}]]) do
    get_assertions(nodes)
  end

  def get_assertions(nodes) when is_list(nodes) do
    nodes
    |> Enum.map(&get_assertion/1)
    |> Enum.filter(fn assertion -> assertion != "" end)
  end
  def get_assertions(nodes) when is_nil(nodes), do: ""

  def get_refutations(nodes) when is_list(nodes) do
    nodes
    |> Enum.map(&get_refutation/1)
    |> Enum.filter(fn refutation -> refutation != ""end)
  end
  def get_refutations(nodes) when is_nil(nodes), do: ""

  def get_assertion({:assert, _line, _content} = node) do
    Macro.to_string(node)
  end
  def get_assertion(_), do: ""
  def get_refutation({:refute, _line, _content} = node) do
    Macro.to_string(node)
  end
  def get_refutation(_), do: ""
end
