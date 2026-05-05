from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from flask_cors import CORS
from dotenv import load_dotenv
import psycopg2
import psycopg2.extras
import os
import uuid

load_dotenv()
app = Flask(__name__)
CORS(app)

DB_CONFIG = {
    'dbname': os.environ.get('DB_NAME', 'universities_db'),
    'user': os.environ.get('DB_USER', 'postgres_ict_project'),
    'password': os.environ.get('DB_PASSWORD', 'postgres'),
    'host': os.environ.get('DB_HOST', 'localhost'),
    'port': os.environ.get('DB_PORT', '5432'),
}

app.secret_key = os.environ.get('SECRET_KEY', 'dev_key_123')

# ── Auth Setup ────────────────────────────────────────────────────────────────

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

class User(UserMixin):
    def __init__(self, id, username, email):
        self.id = id
        self.username = username
        self.email = email

@login_manager.user_loader
def load_user(user_id):
    db = get_db()
    cur = db.cursor()
    cur.execute("SELECT id, username, email FROM users WHERE id = %s", (user_id,))
    row = cur.fetchone()
    db.close()
    if row:
        return User(row['id'], row['username'], row['email'])
    return None


def get_db():
    conn = psycopg2.connect(**DB_CONFIG)
    conn.cursor_factory = psycopg2.extras.RealDictCursor
    return conn

# ── Routes ────────────────────────────────────────────────────────────────────

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')
        
        db = get_db()
        cur = db.cursor()
        
        # Check if user exists
        cur.execute("SELECT id FROM users WHERE username = %s OR email = %s", (username, email))
        if cur.fetchone():
            flash('Username or email already exists')
            db.close()
            return redirect(url_for('signup'))
        
        hashed_pw = generate_password_hash(password)
        cur.execute("INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s)",
                    (username, email, hashed_pw))
        db.commit()
        db.close()
        flash('Account created! Please log in.')
        return redirect(url_for('login'))
        
    return render_template('signup.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        db = get_db()
        cur = db.cursor()
        cur.execute("SELECT * FROM users WHERE username = %s", (username,))
        user_row = cur.fetchone()
        db.close()
        
        if user_row and check_password_hash(user_row['password_hash'], password):
            user_obj = User(user_row['id'], user_row['username'], user_row['email'])
            login_user(user_obj)
            return redirect(url_for('index'))
        else:
            flash('Invalid username or password')
            
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('index'))

@app.route('/')
def index():
    db = get_db()
    cur = db.cursor()
    cur.execute("SELECT * FROM countries ORDER BY name")
    countries = cur.fetchall()
    cur.execute("""
        SELECT COUNT(*) AS total FROM universities
    """)
    stats = cur.fetchone()
    cur.execute("SELECT COUNT(*) AS total FROM programs")
    prog_stats = cur.fetchone()
    db.close()
    return render_template('index.html', countries=countries,
                           uni_count=stats['total'], prog_count=prog_stats['total'])


@app.route('/health')
def health():
    return jsonify({"status": "ok"}), 200


@app.route('/api/feedback', methods=['POST'])
def api_feedback():
    data = request.get_json()
    if not data or 'message' not in data:
        return jsonify({"error": "Missing message"}), 400
    
    # In a real app, we would save this to DB. 
    # For now, just return success.
    return jsonify({"status": "received", "message": data['message']}), 201


@app.route('/countries')
def countries():
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT c.*, COUNT(u.id) AS uni_count
        FROM countries c
        LEFT JOIN universities u ON u.country_id = c.id
        GROUP BY c.id ORDER BY c.name
    """)
    countries = cur.fetchall()
    db.close()
    return render_template('countries.html', countries=countries)


@app.route('/country/<int:country_id>')
def country_detail(country_id):
    db = get_db()
    cur = db.cursor()
    cur.execute("SELECT * FROM countries WHERE id = %s", (country_id,))
    country = cur.fetchone()
    cur.execute("""
        SELECT u.*, array_agg(DISTINCT p.degree_level) AS degree_levels,
               MIN(p.tuition_fee) AS min_fee, MAX(p.tuition_fee) AS max_fee
        FROM universities u
        LEFT JOIN programs p ON p.university_id = u.id
        WHERE u.country_id = %s
        GROUP BY u.id ORDER BY u.name
    """, (country_id,))
    universities = cur.fetchall()
    db.close()
    return render_template('country_detail.html', country=country, universities=universities)


@app.route('/university/<int:uni_id>')
def university_detail(uni_id):
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT u.*, c.name AS country_name
        FROM universities u JOIN countries c ON c.id = u.country_id
        WHERE u.id = %s
    """, (uni_id,))
    university = cur.fetchone()
    cur.execute("SELECT * FROM programs WHERE university_id = %s ORDER BY degree_level, name", (uni_id,))
    programs = cur.fetchall()
    db.close()
    return render_template('university_detail.html', university=university, programs=programs)


@app.route('/explore')
def explore():
    db = get_db()
    cur = db.cursor()
    cur.execute("SELECT * FROM countries ORDER BY name")
    countries = cur.fetchall()
    cur.execute("SELECT DISTINCT field_of_study FROM programs WHERE field_of_study IS NOT NULL ORDER BY field_of_study")
    fields = cur.fetchall()
    db.close()
    return render_template('explore.html', countries=countries, fields=fields)


@app.route('/api/universities')
def api_universities():
    country = request.args.get('country', '')
    degree = request.args.get('degree', '')
    field = request.args.get('field', '')
    language = request.args.get('language', '')
    min_fee = request.args.get('min_fee', 0, type=int)
    max_fee = request.args.get('max_fee', 9999999, type=int)
    min_gpa = request.args.get('min_gpa', 0.0, type=float)

    db = get_db()
    cur = db.cursor()

    query = """
        SELECT DISTINCT u.id, u.name, u.city, u.website, u.logo_url,
               c.name AS country_name,
               MIN(p.tuition_fee) AS min_fee,
               MIN(p.min_gpa) AS min_gpa,
               array_agg(DISTINCT p.degree_level) AS degree_levels,
               array_agg(DISTINCT p.language) AS languages,
               array_agg(DISTINCT p.name) AS program_names
        FROM universities u
        JOIN countries c ON c.id = u.country_id
        JOIN programs p ON p.university_id = u.id
        WHERE 1=1
    """
    params = []

    if country:
        query += " AND c.name = %s"
        params.append(country)
    if degree:
        query += " AND p.degree_level = %s"
        params.append(degree)
    if field:
        query += " AND p.field_of_study = %s"
        params.append(field)
    if language:
        query += " AND p.language = %s"
        params.append(language)
    if max_fee:
        query += " AND p.tuition_fee BETWEEN %s AND %s"
        params += [min_fee, max_fee]
    if min_gpa:
        query += " AND p.min_gpa <= %s"
        params.append(min_gpa)

    query += " GROUP BY u.id, u.name, u.city, u.website, u.logo_url, c.name ORDER BY u.name"

    cur.execute(query, params)
    rows = cur.fetchall()
    db.close()

    results = []
    for r in rows:
        results.append({
            'id': r['id'],
            'name': r['name'],
            'city': r['city'],
            'website': r['website'],
            'logo_url': r['logo_url'],
            'country': r['country_name'],
            'min_fee': r['min_fee'],
            'min_gpa': float(r['min_gpa']) if r['min_gpa'] else None,
            'degree_levels': [d for d in r['degree_levels'] if d],
            'languages': list(set(l for l in r['languages'] if l)),
            'programs': [p for p in r['program_names'] if p][:4],
        })
    return jsonify(results)


@app.route('/eligibility')
@login_required
def eligibility():
    db = get_db()
    cur = db.cursor()
    cur.execute("SELECT DISTINCT field_of_study FROM programs WHERE field_of_study IS NOT NULL ORDER BY field_of_study")
    fields = cur.fetchall()
    db.close()
    return render_template('eligibility.html', fields=fields)


@app.route('/api/eligibility')
def api_eligibility():
    gpa = request.args.get('gpa', 0.0, type=float)
    degree = request.args.get('degree', '')
    field = request.args.get('field', '')
    budget = request.args.get('budget', 9999999, type=int)
    language = request.args.get('language', '')

    db = get_db()
    cur = db.cursor()
    query = """
        SELECT u.id, u.name, u.website, u.logo_url,
               c.name AS country_name,
               p.name AS program_name, p.degree_level, p.min_gpa,
               p.tuition_fee, p.language, p.field_of_study
        FROM programs p
        JOIN universities u ON u.id = p.university_id
        JOIN countries c ON c.id = u.country_id
        WHERE 1=1
    """
    params = []
    if degree:
        query += " AND p.degree_level = %s"
        params.append(degree)
    if field:
        query += " AND p.field_of_study = %s"
        params.append(field)
    if language:
        query += " AND p.language = %s"
        params.append(language)
    if budget:
        query += " AND p.tuition_fee <= %s"
        params.append(budget)
    query += " ORDER BY p.min_gpa ASC"

    cur.execute(query, params)
    rows = cur.fetchall()
    db.close()

    results = []
    for r in rows:
        min_gpa = float(r['min_gpa']) if r['min_gpa'] else 0.0
        if gpa >= min_gpa:
            status = 'eligible'
        elif gpa >= min_gpa - 0.3:
            status = 'borderline'
        else:
            status = 'not_eligible'

        results.append({
            'university_id': r['id'],
            'university': r['name'],
            'country': r['country_name'],
            'program': r['program_name'],
            'degree_level': r['degree_level'],
            'min_gpa': min_gpa,
            'tuition_fee': r['tuition_fee'],
            'language': r['language'],
            'website': r['website'],
            'logo_url': r['logo_url'],
            'status': status,
        })
    return jsonify(results)


@app.route('/recommendations')
@login_required
def recommendations():
    db = get_db()
    cur = db.cursor()
    cur.execute("SELECT DISTINCT field_of_study FROM programs WHERE field_of_study IS NOT NULL ORDER BY field_of_study")
    fields = cur.fetchall()
    cur.execute("SELECT * FROM countries ORDER BY name")
    countries = cur.fetchall()
    db.close()
    return render_template('recommendations.html', fields=fields, countries=countries)


@app.route('/api/recommendations')
def api_recommendations():
    gpa = request.args.get('gpa', 0.0, type=float)
    budget = request.args.get('budget', 9999999, type=int)
    degree = request.args.get('degree', '')
    field = request.args.get('field', '')
    language = request.args.get('language', '')

    db = get_db()
    cur = db.cursor()
    query = """
        SELECT u.id, u.name, u.website, u.logo_url,
               c.name AS country_name,
               p.name AS program_name, p.degree_level, p.min_gpa,
               p.tuition_fee, p.language, p.field_of_study,
               u.ranking_score
        FROM programs p
        JOIN universities u ON u.id = p.university_id
        JOIN countries c ON c.id = u.country_id
        WHERE p.tuition_fee <= %s AND p.min_gpa <= %s
    """
    params = [budget, gpa + 0.5]
    if degree:
        query += " AND p.degree_level = %s"
        params.append(degree)
    if field:
        query += " AND p.field_of_study = %s"
        params.append(field)
    if language:
        query += " AND p.language = %s"
        params.append(language)

    cur.execute(query, params)
    rows = cur.fetchall()
    db.close()

    scored = []
    for r in rows:
        min_gpa = float(r['min_gpa']) if r['min_gpa'] else 0.0
        tuition = r['tuition_fee'] or 0
        ranking = r['ranking_score'] or 50

        # Scoring: higher ranking + closer GPA to threshold + lower tuition relative to budget
        gpa_score = min(30, max(0, (gpa - min_gpa) * 10))
        budget_score = min(30, max(0, (1 - tuition / (budget + 1)) * 30))
        rank_score = min(40, (ranking / 100) * 40)

        total = gpa_score + budget_score + rank_score
        reasons = []
        if gpa >= min_gpa:
            reasons.append(f"Your GPA ({gpa}) meets the {min_gpa} minimum")
        if tuition <= budget * 0.7:
            reasons.append(f"Tuition (${tuition:,}/yr) is well within your budget")
        if ranking >= 70:
            reasons.append("Highly ranked globally")

        scored.append({
            'university_id': r['id'],
            'university': r['name'],
            'country': r['country_name'],
            'program': r['program_name'],
            'degree_level': r['degree_level'],
            'min_gpa': min_gpa,
            'tuition_fee': tuition,
            'language': r['language'],
            'website': r['website'],
            'logo_url': r['logo_url'],
            'score': round(total, 1),
            'reasons': reasons,
        })

    scored.sort(key=lambda x: x['score'], reverse=True)
    # deduplicate by university
    seen = set()
    top = []
    for s in scored:
        if s['university_id'] not in seen:
            seen.add(s['university_id'])
            top.append(s)
        if len(top) == 5:
            break

    return jsonify(top)


@app.route('/scholarships')
@login_required
def scholarships():
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT s.*, u.name AS university_name, c.name AS country_name
        FROM scholarships s
        LEFT JOIN universities u ON u.id = s.university_id
        LEFT JOIN countries c ON c.id = s.country_id
        ORDER BY s.deadline ASC
    """)
    scholarships = cur.fetchall()
    db.close()
    return render_template('scholarships.html', scholarships=scholarships)


@app.route('/compare')
@login_required
def compare():
    return render_template('compare.html')


@app.route('/pathway')
@login_required
def pathway():
    return render_template('pathway.html')


@app.route('/api/university/<int:uni_id>')
def api_university(uni_id):
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT u.*, c.name AS country_name
        FROM universities u JOIN countries c ON c.id = u.country_id
        WHERE u.id = %s
    """, (uni_id,))
    university = dict(cur.fetchone())
    cur.execute("SELECT * FROM programs WHERE university_id = %s ORDER BY degree_level, name", (uni_id,))
    programs = [dict(r) for r in cur.fetchall()]
    for p in programs:
        p['min_gpa'] = float(p['min_gpa']) if p['min_gpa'] else None
        p['tuition_fee'] = float(p['tuition_fee']) if p['tuition_fee'] else None
    university['programs'] = programs
    db.close()
    return jsonify(university)


if __name__ == '__main__':
    app.run(debug=True)
