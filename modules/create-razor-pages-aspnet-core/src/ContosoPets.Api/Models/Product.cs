using System.ComponentModel.DataAnnotations;

namespace ContosoPets.Api.Models
{
    public record Product(
        int Id,
        [Required] string Name,
        [Range(0.01, 9999.99)] decimal Price
    );
}