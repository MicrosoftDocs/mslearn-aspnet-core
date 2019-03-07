using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace ContosoPets.Domain.Models
{
    public partial class Product
    {
        public int Id { get; set; }
        public string Name { get; set; }
        [Column(TypeName = "decimal(18, 2)")]
        public decimal Price { get; set; }
    }
}
