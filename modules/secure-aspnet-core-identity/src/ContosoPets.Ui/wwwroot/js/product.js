async function deleteProduct(productId, xCsrfToken) {
    if(confirm('Are you sure?')) {
        await fetch(`Products/Index/${productId}`, {
            method: 'delete',
            headers: {
                'X-CSRF-TOKEN': xCsrfToken
            }
        })
        .then(response => {
            if (response.status === 204) {
                location.reload();
            }
            else {
                throw `Unable to delete product. HTTP status code: ${response.status}`;
            }
        })
        .catch(error => {
            document.getElementById('spanError').innerText = error;
            console.log(`Product ID ${productId}. ${error}`);
        });
    }
}