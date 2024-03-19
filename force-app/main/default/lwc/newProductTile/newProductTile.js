import { LightningElement, track } from 'lwc';
import getTopProducts from '@salesforce/apex/ProductController.getTopProducts';

export default class ProductList extends LightningElement {
    @track products = [];

    connectedCallback() {
        getTopProducts()
            .then(result => {
                this.products = result.map((product, index) => ({
                    ...product,
                    rank: index + 1 
                }));
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }
}