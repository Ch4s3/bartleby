defmodule Bartleby.TestCase.File do
  @moduledoc """
  A simple struct that holds the internal representation of a test file
  """
  @type t :: %Bartleby.TestCase.File{
              name: String.t,
              docs: String.t,
              module_tags: list(Bartleby.TestCase.Case.t)}
  defstruct name: "", docs: "", module_tags: [], test_cases: []
end
