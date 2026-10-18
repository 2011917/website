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
@app.route('/moon', methods=['GET', 'POST'])
def moon():
    return render_template('moon.html')


@app.route("/notepad")
def notepad():
    return render_template('notepad.html')


@app.route("/RemoteDesktop")
def remotedesktop():
    return render_template('controler.html')


@app.route("/gem")
def gem():
    return render_template("gemini.html")


@app.route("/chat")
def chat():
    return render_template("chat.html")


from share import bp
app.register_blueprint(bp)

if __name__ == '__main__':
    # Get the port from Render's environment, defaulting to 5000 for local development
    port = int(os.environ.get("PORT", 5001))
    
    # 0.0.0.0 tells Flask to listen to all public network interfaces 
    app.run(host='0.0.0.0', port=port, debug=False)
