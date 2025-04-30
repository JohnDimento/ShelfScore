// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import Alpine from 'alpinejs'

console.log('Initializing Alpine.js...')
window.Alpine = Alpine
Alpine.start()
console.log('Alpine.js initialized!')
