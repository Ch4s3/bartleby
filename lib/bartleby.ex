defmodule Bartleby do
  use Firex
  @moduledoc """
  Documentation for Bartleby.
  """
  @doc """
  document the tests for a given path
  """
  @spec document_tests(String.t) :: String.t
  def document_tests(path) do
    IO.puts "Parsing directory '#{path}'"
    manifest = Bartleby.Parser.parse_directory(path)
    IO.puts "Manifest for '#{path}':"
    IO.inspect manifest
  end
end
