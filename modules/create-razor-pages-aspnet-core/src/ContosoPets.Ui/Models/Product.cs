using System.ComponentModel.DataAnnotations;

namespace ContosoPets.Ui.Models
{
    public class Product
    {
        public int Id { get; set; }

        [Required]
        public string Name { get; set; }

        [Range(0.01, 9999.99)]
        public decimal Price { get; set; }
    }
}
