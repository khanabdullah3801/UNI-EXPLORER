import pytest
from app import app
import json
from unittest.mock import patch, MagicMock

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health(client):
    """Test the health check endpoint."""
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'ok'

@patch('app.get_db')
def test_get_universities(mock_get_db, client):
    """Test the GET universities API endpoint with mocked database."""
    # Mock database connection and cursor
    mock_db = MagicMock()
    mock_cur = MagicMock()
    mock_get_db.return_value = mock_db
    mock_db.cursor.return_value = mock_cur
    
    # Define mock data
    mock_cur.fetchall.return_value = [
        {
            'id': 1, 'name': 'Test Uni', 'city': 'Test City', 
            'website': 'http://test.edu', 'logo_url': None, 
            'country_name': 'Test Country', 'min_fee': 1000, 
            'min_gpa': 3.0, 'degree_levels': ['Bachelors'], 
            'languages': ['English'], 'program_names': ['CS']
        }
    ]
    
    response = client.get('/api/universities')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert len(data) > 0
    assert data[0]['name'] == 'Test Uni'

def test_post_feedback(client):
    """Test the POST feedback endpoint."""
    feedback_data = {'message': 'Great app!'}
    response = client.post('/api/feedback', 
                           data=json.dumps(feedback_data),
                           content_type='application/json')
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['status'] == 'received'
    assert data['message'] == 'Great app!'

def test_post_feedback_invalid(client):
    """Test the POST feedback endpoint with invalid data."""
    feedback_data = {'not_a_message': 'oops'}
    response = client.post('/api/feedback', 
                           data=json.dumps(feedback_data),
                           content_type='application/json')
    assert response.status_code == 400
    data = json.loads(response.data)
    assert 'error' in data

@patch('app.get_db')
def test_index_page(mock_get_db, client):
    """Test the index page renders correctly with mocked database."""
    mock_db = MagicMock()
    mock_cur = MagicMock()
    mock_get_db.return_value = mock_db
    mock_db.cursor.return_value = mock_cur
    
    # Mock data for index route
    mock_cur.fetchall.return_value = [{'id': 1, 'name': 'USA', 'flag_emoji': '🇺🇸'}]
    mock_cur.fetchone.side_effect = [{'total': 100}, {'total': 500}]
    
    response = client.get('/')
    assert response.status_code == 200
    assert b"Find Your" in response.data
