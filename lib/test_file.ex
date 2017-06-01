defmodule TestFile do
  @moduledoc """
  A simple struct that holds the internal representation of a test file
  """
  @type t :: %TestFile{name: String.t, docs: String.t, module_tags: list(TestCase.t)}
  defstruct name: "", docs: "", module_tags: [], test_cases: []
end
