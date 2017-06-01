defmodule TestCase do
  @moduledoc """
  A simple struct that holds the internal representation of an individual case
  in a `TestFile`'s test_cases field.

  """
  @type t :: %TestCase{name: String.t, assertions: list(String.t), refutations: list(String.t)}
  defstruct name: "", assertions: [], refutations: []
end
