using ClientA.Api;
 // Make sure this matches your actual namespace for the Product class
using Xunit;

namespace ClientA.Api.Tests;

public class ProductTests
{
    [Fact]
    public void Product_CanBeCreated_WithValidProperties()
    {
        // Arrange
        var expectedName = "Cloud Architecture Course";
        var expectedPrice = 99.99m;

        // Act
        var product = new Product 
        { 
            Name = expectedName, 
            Price = expectedPrice 
        };

        // Assert
        Assert.Equal(expectedName, product.Name);
        Assert.Equal(expectedPrice, product.Price);
    }
}