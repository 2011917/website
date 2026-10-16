from flask import Blueprint, request, jsonify, render_template

bp = Blueprint('share', __name__)
rooms = {}  # room -> {recipient: [messages]}

@bp.route('/share')
def page():
    return render_template('share.html')

@bp.post('/share/send/<room>/<to>')
def send(room, to):
    rooms.setdefault(room, {}).setdefault(to, []).append(request.json)
    return '', 204

@bp.get('/share/poll/<room>/<me>')
def poll(room, me):
    return jsonify(rooms.setdefault(room, {}).pop(me, []))