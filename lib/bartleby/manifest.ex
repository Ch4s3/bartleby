defmodule Bartleby.Manifest do
  @moduledoc """
  A simple struct that holds the internal representation of a list of test files
  """
  @type t :: %Bartleby.Manifest{test_files: list(Bartleby.TestCase.File.t)}
  defstruct test_files: []
end
