require "application_system_test_case"

class PruebasTest < ApplicationSystemTestCase
  setup do
    @prueba = pruebas(:one)
  end

  test "visiting the index" do
    visit pruebas_url
    assert_selector "h1", text: "Pruebas"
  end

  test "should create prueba" do
    visit pruebas_url
    click_on "New prueba"

    fill_in "Description", with: @prueba.description
    fill_in "Nombre", with: @prueba.nombre
    click_on "Create Prueba"

    assert_text "Prueba was successfully created"
    click_on "Back"
  end

  test "should update Prueba" do
    visit prueba_url(@prueba)
    click_on "Edit this prueba", match: :first

    fill_in "Description", with: @prueba.description
    fill_in "Nombre", with: @prueba.nombre
    click_on "Update Prueba"

    assert_text "Prueba was successfully updated"
    click_on "Back"
  end

  test "should destroy Prueba" do
    visit prueba_url(@prueba)
    click_on "Destroy this prueba", match: :first

    assert_text "Prueba was successfully destroyed"
  end
end
