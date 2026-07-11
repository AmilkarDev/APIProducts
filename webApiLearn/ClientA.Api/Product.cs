using System.ComponentModel.DataAnnotations;

public class Product
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string Name { get; set; } = string.Empty;

    [Range(0, double.MaxValue)]
    public decimal Price { get; set; }
}
