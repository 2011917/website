from flask import Flask, render_template, request, redirect, url_for
import os

app = Flask(__name__)

# 1. Home Route - Passing data to HTML
@app.route('/')
def home():
    # We can pass variables (like dynamic names) directly into our HTML file
    current_visitor = "Developer"
    return render_template('index.html', user_name=current_visitor)

# 2. Contact Route - Handling both viewing the page (GET) and submitting the form (POST)
@app.route('/contact', methods=['GET', 'POST'])
def contact():
    if request.method == 'POST':
        # Grab the text entered by the user in the HTML form
        submitted_text = request.form.get('user_message')
        
        # In a real app, you would save this to a database. 
        # For now, we'll just print it to the terminal console.
        print(f"--- NEW MESSAGE RECEIVED: {submitted_text} ---")
        
        # Redirect the user back to the home page after submitting
        return redirect(url_for('home'))
        
    # If it's a GET request, just show the HTML form page
    return render_template('contact.html')

@app.route("/notepad")
def uploader():
    return render_template('notepad.html')



if __name__ == '__main__':
    # Get the port from Render's environment, defaulting to 5000 for local development
    port = int(os.environ.get("PORT", 5000))
    
    # 0.0.0.0 tells Flask to listen to all public network interfaces 
    app.run(host='0.0.0.0', port=port, debug=False)
