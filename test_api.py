"""
Test script for OCRimageflow API
Prueba todos los endpoints principales
"""

import requests
import json
import os

# Change this to your API URL
BASE_URL = "http://localhost:8000"
# BASE_URL = "https://your-app.up.railway.app"  # Para producción

def test_health():
    """Test health endpoint"""
    print("\n🔍 Testing /health...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_get_tiers():
    """Test tiers endpoint"""
    print("\n📊 Testing /tiers...")
    response = requests.get(f"{BASE_URL}/tiers")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_register():
    """Test user registration"""
    print("\n📝 Testing user registration...")
    data = {
        "email": "testuser@ocrflow.com",
        "password": "testpassword123",
        "name": "Test User",
        "tier": "starter"
    }
    response = requests.post(f"{BASE_URL}/auth/register", json=data)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"✅ User registered successfully")
        print(f"Token: {result['access_token'][:30]}...")
        return result['access_token']
    else:
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return None

def test_login():
    """Test user login"""
    print("\n🔐 Testing user login...")
    data = {
        "email": "testuser@ocrflow.com",
        "password": "testpassword123"
    }
    response = requests.post(f"{BASE_URL}/auth/login", json=data)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"✅ Login successful")
        print(f"Token: {result['access_token'][:30]}...")
        print(f"User: {result['user']['name']} ({result['user']['tier']})")
        return result['access_token']
    else:
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return None

def test_get_stats(token):
    """Test getting user stats"""
    print("\n📈 Testing /usage/stats...")
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/usage/stats", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_process_batch(token, image_paths):
    """Test batch image processing"""
    print("\n🖼️  Testing /process/batch...")
    
    if not image_paths:
        print("⚠️  No image files provided. Skipping this test.")
        print("   To test, provide image paths in the main() function")
        return False
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Prepare files
    files = []
    for img_path in image_paths:
        if os.path.exists(img_path):
            files.append(('files', (os.path.basename(img_path), open(img_path, 'rb'), 'image/jpeg')))
        else:
            print(f"⚠️  Image not found: {img_path}")
    
    if not files:
        print("❌ No valid images found")
        return False
    
    print(f"📤 Uploading {len(files)} images...")
    response = requests.post(f"{BASE_URL}/process/batch", headers=headers, files=files)
    
    # Close files
    for _, file_tuple in files:
        file_tuple[1].close()
    
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print("✅ Batch processed successfully!")
        print(f"   Images processed: {result['images_processed']}")
        print(f"   Industry detected: {result['industry_detected']}")
        print(f"   Excel URL: {result.get('excel_url', 'N/A')}")
        print(f"   Remaining images: {result.get('remaining_images', 'N/A')}")
        return True
    else:
        print(f"❌ Error: {json.dumps(response.json(), indent=2)}")
        return False

def test_get_logs(token):
    """Test getting usage logs"""
    print("\n📋 Testing /usage/logs...")
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/usage/logs?limit=10", headers=headers)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"Logs found: {len(result['logs'])}")
        for log in result['logs'][:3]:
            print(f"  - {log['action']} ({log['created_at']})")
        return True
    else:
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return False

def main():
    print("=" * 70)
    print("🚀 OCRimageflow API Test Suite")
    print("=" * 70)
    print(f"Testing: {BASE_URL}")
    
    # Test 1: Health check
    if not test_health():
        print("\n❌ Health check failed. Is the server running?")
        return
    print("✅ Health check passed!")
    
    # Test 2: Get tiers
    test_get_tiers()
    
    # Test 3: Register (or login if already exists)
    token = test_register()
    if not token:
        print("\n⚠️  Registration failed (user might exist). Trying login...")
        token = test_login()
    
    if not token:
        print("\n❌ Could not get authentication token")
        return
    
    print(f"\n✅ Got authentication token")
    
    # Test 4: Get stats
    test_get_stats(token)
    
    # Test 5: Process batch (OPTIONAL - requires images)
    # Descomenta y agrega rutas de imágenes de prueba:
    # test_process_batch(token, [
    #     "C:/path/to/image1.jpg",
    #     "C:/path/to/image2.jpg"
    # ])
    
    print("\n⚠️  Image processing test skipped (no images provided)")
    print("   To test image processing, uncomment the lines above and add image paths")
    
    # Test 6: Get logs
    test_get_logs(token)
    
    print("\n" + "=" * 70)
    print("✅ All tests completed!")
    print("=" * 70)
    print("\n💡 Next steps:")
    print("   1. Add image paths to test batch processing")
    print("   2. Check your S3 bucket for uploaded files")
    print("   3. Try the API docs at: " + BASE_URL + "/docs")

if __name__ == "__main__":
    try:
        main()
    except requests.exceptions.ConnectionError:
        print(f"\n❌ Could not connect to API at {BASE_URL}")
        print("   Make sure the server is running with: uvicorn main:app --reload")
    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
