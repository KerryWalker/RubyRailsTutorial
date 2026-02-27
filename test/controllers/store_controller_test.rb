require "test_helper"

class StoreControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get store_index_url
    assert_response :success
    assert_select "nav a", minimum: 4
    assert_select "main ul li", 3
    assert_select "h2", "Programming Ruby 1.9"
    assert_select "div", /\$[,\d]+\.\d\d/
  end

  test "should show all products on index" do
    get store_index_url
    assert_response :success
    
    # Check that all products from fixtures are displayed
    Product.all.each do |product|
      assert_select "h2", text: product.title
      assert_select "div", text: /#{Regexp.escape(sprintf("$%.2f", product.price))}/
    end
  end

  test "should display products ordered by title" do
    get store_index_url
    assert_response :success
    
    # Extract product titles from response in order
    doc = Nokogiri::HTML(@response.body)
    titles = doc.css("main ul li h2").map(&:text).map(&:strip)
    
    # Verify products are ordered by title
    expected_titles = Product.order(:title).pluck(:title)
    assert_equal expected_titles, titles
  end

  test "should display product images" do
    get store_index_url
    assert_response :success
    
    # Check that there are product images displayed
    assert_select "main ul li img", count: Product.count
  end

  test "should display product descriptions" do
    get store_index_url
    assert_response :success
    
    # Check that descriptions are rendered (sanitized HTML)
    assert_select "p", minimum: Product.count
  end

  test "should display formatted prices" do
    get store_index_url
    assert_response :success
    
    # Verify currency formatting is present
    Product.all.each do |product|
      # Check for currency format (e.g., $49.50)
      assert_match /\$\d+\.\d{2}/, @response.body
    end
  end

  test "index with no products should render without errors" do
    # Remove all products (delete line items first due to foreign key constraint)
    LineItem.delete_all
    Product.delete_all
    
    get store_index_url
    assert_response :success
    assert_select "main ul"
    assert_select "main ul li", count: 0
  end

  test "index with single product should render correctly" do
    # Keep only one product (delete line items first due to foreign key constraint)
    LineItem.delete_all
    Product.where.not(id: products(:ruby).id).delete_all
    
    get store_index_url
    assert_response :success
    assert_select "main ul li", count: 1
    assert_select "h2", text: products(:ruby).title
  end

  test "should use caching for products" do
    get store_index_url
    assert_response :success
    
    # Verify the cache directive is in the view
    assert_match /cache/, File.read(Rails.root.join("app/views/store/index.html.erb"))
  end

  test "products should be ordered alphabetically" do
    # Create test products with specific titles using existing image
    # Delete line items first due to foreign key constraint
    LineItem.delete_all
    Product.delete_all
    Product.create!(
      title: "Zebra Book",
      description: "Last book",
      image_url: "lorem.jpg",
      price: 29.99
    )
    Product.create!(
      title: "Alpha Book",
      description: "First book",
      image_url: "lorem.jpg",
      price: 19.99
    )
    Product.create!(
      title: "Beta Book",
      description: "Second book",
      image_url: "lorem.jpg",
      price: 24.99
    )
    
    get store_index_url
    assert_response :success
    
    # Extract product titles from response in order
    doc = Nokogiri::HTML(@response.body)
    titles = doc.css("main ul li h2").map(&:text).map(&:strip)
    
    # Should be alphabetically ordered
    assert_equal ["Alpha Book", "Beta Book", "Zebra Book"], titles
  end
end
