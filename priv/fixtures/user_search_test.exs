defmodule Services.Search.UserSearchClientTest do
  use Services.SchemaCase, async: false

  import Services.Factory

  alias Services.{Search.UserSearchClient, UserClient}

  setup do
    company     = insert(:company)
    other_user  = insert(:user, company: company)
    {:ok, user} = UserClient.create(%{company: company,
                                      emailAddress: "bdogg@dingobank.com",
                                      firstName: "Billy",
                                      lastName: "Dogg"})

    {:ok, company: company, user: user, other_user: other_user}
  end

  @params %{"sort" => "firstName",
            "order" => "asc",
            "case_sensitive" => 0,
            "page_size" => "25",
            "page_number" => "1"}

  @doc """
  ## Simple Search
  foo bar bizz fubbb alfgjoir rgoiwtoijrgw  rgwoigoijwg tiowngoiwj grwiungoirwgori
  rgowroigjwo groiwjgroi2g rgiowrgiowg giorwjgiorwg rgiuw3girougnrwgiu giogri2
  foo bar bizz fubbb alfgjoir rgoiwtoijrgw  rgwoigoijwg tiowngoiwj grwiungoirwgori
  """
  test "finds a user if their email is given.", %{company: company, user: user, other_user: other_user} do
    users  = UserSearchClient.search("bdogg@dingobank.com", company, @params)
    emails = Enum.map(users.entries, &(&1.emailAddress))

    assert !(Enum.member?(emails, other_user.emailAddress))
    assert Enum.member?(emails, user.emailAddress)
  end

  test "finds a user if their first name is given", %{company: company, user: user, other_user: other_user} do
    users       = UserSearchClient.search("Billy", company, @params)
    first_names = Enum.map(users.entries, &(&1.firstName))

    assert !(Enum.member?(first_names, other_user.firstName))
    assert Enum.member?(first_names, user.firstName)
  end

  test "finds a user if their last name is given", %{company: company, user: user, other_user: other_user}do
    users      = UserSearchClient.search("Dogg", company, @params)
    last_names = Enum.map(users.entries, &(&1.lastName))

    assert !(Enum.member?(last_names, other_user.lastName)) == true
    assert Enum.member?(last_names, user.lastName) == true
  end

  @doc """
  ## Tag Search
  foo bar bizz fubbb alfgjoir rgoiwtoijrgw  rgwoigoijwg tiowngoiwj grwiungoirwgori
  rgowroigjwo groiwjgroi2g rgiowrgiowg giorwjgiorwg rgiuw3girougnrwgiu giogri2
  foo bar bizz fubbb alfgjoir rgoiwtoijrgw  rgwoigoijwg tiowngoiwj grwiungoirwgori
  """
  test "can search by multiple fields (AKA by tags)", %{company: company} do
    {:ok, _user2} = UserClient.create(%{company: company,
                                       emailAddress: "dtoy@dingobank.com",
                                       firstName: "Dogg",
                                       lastName: "toy"})
    response = UserSearchClient.search("Dogg", company, @params)
    users    = response.entries

    assert length(users) == 2
    assert List.first(users).lastName == "Dogg"
    assert List.last(users).firstName == "Dogg"
  end

  test "can search by multiple fields for multiple search terms", %{company: company} do
    {:ok, _user2} = UserClient.create(%{company: company,
                                       emailAddress: "dtoy@dingobank.com",
                                       firstName: "dogg",
                                       lastName: "toy"})
    {:ok, _user3} = UserClient.create(%{company: company,
                                       emailAddress: "bigdogg@dingobank.com",
                                       firstName: "big",
                                       lastName: "dogg"})
    response = UserSearchClient.search("Dogg dogg dingobank", company, @params)
    users    = response.entries

    assert length(users) == 3
  end

  @doc """
  foo bar bizz fubbb alfgjoir rgoiwtoijrgw  rgwoigoijwg tiowngoiwj grwiungoirwgori
  rgowroigjwo groiwjgroi2g rgiowrgiowg giorwjgiorwg rgiuw3girougnrwgiu giogri2
  foo bar bizz fubbb alfgjoir rgoiwtoijrgw  rgwoigoijwg tiowngoiwj grwiungoirwgori
  """
  test "can offer interface to search on frontend concept of group", %{company: company, other_user: other_user} do
    new_user        = %Services.Schema.User{firstName: "Bruce", lastName: "Wayne", emailAddress: "bwayne@dingobank.com", company: company}
    {:ok, new_user} = Repo.insert(new_user)
    uuid1           = tag_uuid()
    uuid2           = tag_uuid()
    tag             = %Services.Schema.CompanyTag{tag: "Group", value: "Development", company: company, tagUUID: uuid1}
    other_tag       = %Services.Schema.CompanyTag{tag: "Group", value: "Development", company: other_user.company, tagUUID: uuid2}
    now             = Ecto.DateTime.utc
    Services.Repo.insert(tag)
    Services.Repo.insert(other_tag)
    Repo.insert_all("UserTagInstances", [[userId: new_user.id, companyTagUUID: tag.tagUUID, created: now, modified: now, version: now]])
    Repo.insert_all("UserTagInstances", [[userId: 508866, companyTagUUID: other_tag.tagUUID, created: now, modified: now, version: now]])
    response = UserSearchClient.search("Development", company, @params)
    users    = response.entries

    assert length(users) == 1
  end

  defp tag_uuid do
    uuid =
      "abcdefghijklmnopqrstuvwxyz1234567890"
      |> String.split("")
      |> Enum.shuffle
      |> Enum.join
    :erlang.binary_part(uuid, {byte_size(uuid), -16})
  end
end
