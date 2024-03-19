import { LightningElement, track } from 'lwc';
import getChatterGroupFeed from '@salesforce/apex/ProductController.getChatterGroupFeed';

export default class ChatterAnnouncementsLwc extends LightningElement {
    @track feedItems = [];

    connectedCallback() {
        getChatterGroupFeed()
            .then(result => {
                this.feedItems = result.map(item => ({
                    ...item,
                    CreatedDate: new Date(item.CreatedDate).toLocaleString()
                }));
            })
            .catch(error => {
                console.error('Error retrieving Chatter Group Feed:', error);
            });
    }
}