using System.ComponentModel.DataAnnotations;

namespace ContosoPets.Ui.Models
{
    public class Product
    {
        public int Id { get; set; }
        [Required]
        public string Name { get; set; }
        [Required]
        [Range(minimum:0.01, maximum:9999.99)]
        public decimal Price { get; set; }
    }
}
