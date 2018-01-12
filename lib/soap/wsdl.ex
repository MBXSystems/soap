defmodule Soap.Wsdl do
  @moduledoc """
  Provides functions for parsing wsdl file
  """

  import SweetXml, except: [parse: 1]

  @spec parse_from_file(String.t()) :: tuple()
  def parse_from_file(path) do
    {:ok, wsdl} = File.read(path)
    parse(wsdl)
  end

  @spec parse_from_url(String.t()) :: tuple()
  def parse_from_url(path) do
    %HTTPoison.Response{body: wsdl} = HTTPoison.get!(path)
    parse(wsdl)
  end

  @spec parse(String.t()) :: tuple()
  def parse(wsdl) do
    {:ok, wsdl}
  end

  @spec get_namespaces(String.t()) :: map()
  def get_namespaces(wsdl) do
    wsdl
    |> xpath(~x"//wsdl:definitions/namespace::*"l)
    |> Enum.map(&get_namespace(&1, wsdl))
    |> Enum.into(%{})
  end

  defp get_namespace(namespaces_node, wsdl) do
    {_, _, _, key, value} = namespaces_node
    string_key = key |> to_string
    value = Atom.to_string(value)

    cond do
      xpath(wsdl, ~x"//wsdl:definitions[@targetNamespace='#{value}']") ->
        {string_key, %{value: value, type: :wsdl}}
      xpath(wsdl, ~x"//wsdl:types/xsd:schema/xsd:import[@namespace='#{value}']") ->
        {string_key, %{value: value, type: :xsd}}
      true ->
        {string_key, %{value: value, type: :soap}}
    end
  end

  @spec get_endpoint(String.t()) :: String.t()
  def get_endpoint(wsdl) do
    wsdl
    |> xpath(~x"//wsdl:definitions/wsdl:service/wsdl:port/soap:address/@location")
    |> to_string
  end

  def get_complex_types(wsdl) do
    xpath(wsdl, ~x"//wsdl:types/xsd:schema/xsd:element"l, name: ~x"./@name"s, type: ~x"./@type"s)
  end
end