defmodule Test.File do
  @moduledoc """
  A simple struct that holds the internal representation of a test file
  """
  @type t :: %Test.File{name: String.t, docs: String.t, module_tags: list(TestCase.t)}
  defstruct name: "", docs: "", module_tags: [], test_cases: []
end
