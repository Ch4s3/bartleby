defmodule Bartleby.Parser do
  alias Bartleby.TestCase.Case
  alias Bartleby.Manifest
  alias Bartleby.Parser
  @moduledoc """
  The parser takes a file_name as an argument and converts it to an AST using
  `Code.string_to_quoted!`. It then parses the ast and builds a struct representing
  the test file and its tags, cases, and assertions.
  ##Examples

    iex> File.cp("fixtures/phoenix_controller_test.txt", "fixtures/phoenix_controller_test.exs")
    ...> test_case = Bartleby.Parser.parse("fixtures/phoenix_controller_test.exs")
    ...> File.rm("fixtures/phoenix_controller_test.exs")
    ...> test_case
    %Bartleby.TestCase.File{docs: "For test purposes, here are the docs\\nsome more lines\\n",
      module_tags: ["integration", "something_else"],
      name: "PhoenixControllerTest",
      test_cases: [
        %Bartleby.TestCase.Case{
          assertions: [
            "assert(response.status() == 200)",
            "assert(String.contains?(response.resp_body(), expectation_1))"],
          name: "#POST /api/v1/the_apt returns proper response",
          refutations: [
            "refute(response.status() == 400)"
          ]
        }
      ]
    }
  """

  @spec parse_directory(String.t) :: Bartleby.Manifest.t
  def parse_directory(dir) do
    %Manifest{test_files: parse_files(dir)}
  end

  def parse_files(dir) do
    dir
    |> File.ls!
    |> Enum.reduce(fn (file, acc) -> [get_file("#{dir}/#{file}") | acc] end)
  end

  def get_file(path)do
    case File.dir?(path) do
      true ->
        parse_files(path)
      false ->
        Parser.parse(path)
    end
  end

  @spec parse(String.t) :: Bartleby.TestCase.File.t
  def parse(file_name) do
    with {:ok, file_name} <- check_file(file_name),
         {:ok, file} <- File.read(file_name),
         {:ok, ast} <- Code.string_to_quoted(file),
         {:ok, nodes} <- get_nodes(ast) do

      %Bartleby.TestCase.File{
       name: name(ast),
       module_tags: module_tags(nodes),
       docs: get_docs(nodes),
       test_cases: get_test_cases(nodes)
      }
    else {:error, error} ->
      error
    end
  end

  def check_file(file_name) do
    cond do
      Regex.match?(~r/test_helper.exs/, file_name) ->
        # this is broken
        {:error, "excluded file"}
      Regex.match?(~r/exs/, file_name) ->
        {:ok, file_name}
      true ->
        {:error, "bad file type"}
    end
  end

  def name({:defmodule, _, [module_line | _rest]}) do
    module_line
    |> get_module_name
  end

  def get_module_name({:__aliases__, _line, name}) do
    name |> List.last |> Atom.to_string
  end

  def module_tags (nodes) do
    nodes
    |> Enum.filter(fn n -> _is_modult_tag_node?(n) end)
    |> get_module_tag_names
  end

  def get_module_tag_names(name_tuples) when is_list(name_tuples) do
    name_tuples
    |> Enum.map(&get_module_tag_names/1)
  end
  def get_module_tag_names({:@, _l, [{:moduletag, _l2, [name]}]}) do
    name |> Atom.to_string
  end

  def get_docs(nodes) do
    nodes
    |> Enum.find(fn n -> _is_doc_node?(n) end)
    |> _parse_doc_node
  end

  def get_test_cases(nodes) do
    nodes
    |> Enum.map(&build_test_case/1)
    |> Enum.reject(fn(test_case) -> test_case == nil end)
  end

  def get_nodes(ast) when is_nil(ast),  do: {:error, "no ast"}
  def get_nodes({_def, _l, rest}) when rest == [], do: {:error, "no nodes"}
  def get_nodes({_def, _l, rest}) do
    body =
      try do
         rest |> Enum.at(1) |> Enum.at(0)
      catch
        _error, _ast ->
        IO.puts("Error parsing ast")
        {nil, {nil, nil, []}}
      end
    {_do, {_block, _meta_data, nodes}} = body
    {:ok, nodes}
  end

  defp _is_modult_tag_node?({:@, _l, [{:moduletag, _l2, [_text]}]}) do
    true
  end
  defp _is_modult_tag_node?(_), do: false

  defp _is_doc_node?({:@, _l, [{:moduledoc, _l2, [_text]}]}) do
    true
  end
  defp _is_doc_node?(_), do: false

  defp _parse_doc_node(node) when is_nil(node), do: []
  defp _parse_doc_node(node) when is_tuple(node) do
    node
    |> Tuple.to_list
    |> Enum.at(2)
    |> Enum.at(0)
    |> Tuple.to_list
    |> Enum.at(2)
    |> Enum.at(0)
  end

  def build_test_case({:test, _line, test}) do
    %Case{
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

  def get_refutations([_name, [{_do, {_block, _meta, nodes}}]]) do
    get_refutations(nodes)
  end

  def get_refutations(nodes) when is_list(nodes) do
    nodes
    |> Enum.map(&get_refutation/1)
    |> Enum.filter(fn refutation -> refutation != "" end)
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
