using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ContosoPets.Api.Models
{
    public partial class Customer
    {
        public Customer()
        {
            Orders = new HashSet<Order>();
        }

        public int Id { get; set; }
        [Required]
        public string FirstName { get; set; }
        [Required]
        public string LastName { get; set; }
        public string StreetAddress { get; set; }
        public string City { get; set; }
        public string StateOrProvinceAbbr { get; set; }
        public string Country { get; set; }
        public string PostalCode { get; set; }
        public string Phone { get; set; }
        public string Email { get; set; }

        public ICollection<Order> Orders { get; set; }
    }
}
