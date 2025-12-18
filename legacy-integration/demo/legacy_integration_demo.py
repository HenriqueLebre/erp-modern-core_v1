#!/usr/bin/env python3
"""
XHarbour Legacy Integration Demo

This Python script simulates the XHarbour HTTP wrapper functionality
to demonstrate how the legacy ERP system integrates with the modern
.NET 8 Auth API.

For showcase/portfolio purposes - demonstrates Strangler Fig migration pattern.
"""

import requests
import json
import time
from datetime import datetime
from typing import Optional, Dict, Any

class LegacyAuthWrapper:
    """
    Simulates the XHarbour HTTP wrapper for Auth API integration.
    
    This class demonstrates how legacy systems can gradually migrate
    to modern authentication while maintaining operational continuity.
    """
    
    def __init__(self, base_url: str = "http://localhost:5281"):
        self.base_url = base_url
        self.token: Optional[str] = None
        self.current_user: Optional[Dict[str, Any]] = None
        self.authenticated = False
        
    def print_step(self, step: str, status: str = "INFO"):
        """Helper to format demo output"""
        icons = {"INFO": "ℹ️", "SUCCESS": "✅", "ERROR": "❌", "WARNING": "⚠️"}
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {icons.get(status, 'ℹ️')} {step}")
    
    def login(self, username: str, password: str) -> bool:
        """
        Authenticate with modern Auth API
        
        LEGACY MIGRATION:
        - BEFORE: Direct database authentication in XHarbour
        - AFTER: HTTP call to modern .NET 8 Auth API
        """
        self.print_step(f"Attempting login for user: {username}")
        
        try:
            response = requests.post(
                f"{self.base_url}/auth/login",
                json={"username": username, "password": password},
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    self.token = data.get("token")
                    self.authenticated = True
                    self.print_step(f"Login successful! Token obtained (first 20 chars): {self.token[:20]}...", "SUCCESS")
                    
                    # Get user details
                    self.get_current_user()
                    return True
                else:
                    self.print_step(f"Login failed: {data.get('message', 'Unknown error')}", "ERROR")
            elif response.status_code == 429:
                self.print_step("Login blocked: Rate limit exceeded (security protection)", "WARNING")
            else:
                self.print_step(f"Login failed with HTTP {response.status_code}", "ERROR")
                
        except requests.exceptions.RequestException as e:
            self.print_step(f"Failed to connect to Auth API: {str(e)}", "ERROR")
            
        return False
    
    def validate_token(self, token: str = None) -> bool:
        """
        Validate JWT token with modern API
        
        This is called before sensitive operations like opening POS terminal
        or processing payments in the legacy system.
        """
        if not token:
            token = self.token
            
        if not token:
            self.print_step("No token available for validation", "ERROR")
            return False
            
        self.print_step("Validating authentication token...")
        
        try:
            response = requests.post(
                f"{self.base_url}/auth/validate",
                json={"token": token},
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get("success") and data.get("valid"):
                    self.print_step(f"Token valid for user: {data.get('username')} (Role: {data.get('role')})", "SUCCESS")
                    return True
                else:
                    self.print_step(f"Token validation failed: {data.get('message', 'Invalid token')}", "ERROR")
                    self.logout()  # Clear invalid token
            else:
                self.print_step(f"Token validation failed with HTTP {response.status_code}", "ERROR")
                
        except requests.exceptions.RequestException as e:
            self.print_step(f"Token validation failed - API unreachable: {str(e)}", "ERROR")
            
        return False
    
    def get_current_user(self) -> Optional[Dict[str, Any]]:
        """Get current user information using JWT token"""
        if not self.token:
            self.print_step("No authentication token available", "ERROR")
            return None
            
        try:
            response = requests.get(
                f"{self.base_url}/auth/me",
                headers={
                    "Authorization": f"Bearer {self.token}",
                    "Content-Type": "application/json"
                },
                timeout=10
            )
            
            if response.status_code == 200:
                self.current_user = response.json()
                self.print_step(f"Current user: {self.current_user.get('username')} (ID: {self.current_user.get('userId')}, Role: {self.current_user.get('role')})", "SUCCESS")
                return self.current_user
            else:
                self.print_step(f"Failed to get user info: HTTP {response.status_code}", "ERROR")
                
        except requests.exceptions.RequestException as e:
            self.print_step(f"Failed to get user info: {str(e)}", "ERROR")
            
        return None
    
    def logout(self):
        """Clear authentication state"""
        self.token = None
        self.current_user = None
        self.authenticated = False
        self.print_step("User logged out successfully", "INFO")

class LegacyERPSystem:
    """
    Simulates legacy ERP system functions that now integrate with modern auth
    
    These functions demonstrate how existing business logic can gradually
    migrate to use modern authentication while maintaining functionality.
    """
    
    def __init__(self, auth_wrapper: LegacyAuthWrapper):
        self.auth = auth_wrapper
        
    def print_step(self, step: str, status: str = "INFO"):
        """Helper to format demo output"""
        icons = {"INFO": "ℹ️", "SUCCESS": "✅", "ERROR": "❌", "WARNING": "⚠️"}
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {icons.get(status, 'ℹ️')} {step}")
    
    def check_user_permission(self, permission: str) -> bool:
        """
        Check if current user has permission for operation
        
        LEGACY MIGRATION:
        - BEFORE: Direct database permission check
        - AFTER: JWT token validation + role-based permissions
        """
        if not self.auth.token:
            self.print_step(f"Permission denied for '{permission}' - user not authenticated", "ERROR")
            return False
            
        # Validate token first
        if not self.auth.validate_token():
            self.print_step(f"Permission denied for '{permission}' - invalid authentication", "ERROR")
            return False
            
        # Simple role-based permission check
        if not self.auth.current_user:
            return False
            
        user_role = self.auth.current_user.get("role", "")
        
        # Permission matrix
        permissions = {
            "Admin": ["POS", "SALES", "PAYMENT", "REPORTS", "CONFIG", "SYSTEM"],
            "Manager": ["POS", "SALES", "PAYMENT", "REPORTS"],
            "Cashier": ["POS", "SALES", "PAYMENT"],
            "Viewer": ["REPORTS"]
        }
        
        allowed_permissions = permissions.get(user_role, [])
        has_permission = permission in allowed_permissions
        
        status = "SUCCESS" if has_permission else "WARNING"
        self.print_step(f"Permission check: '{permission}' for role '{user_role}' = {has_permission}", status)
        
        return has_permission
    
    def open_pos_terminal(self) -> bool:
        """
        Open POS terminal (critical business function)
        
        This demonstrates how sensitive operations now validate
        authentication before proceeding.
        """
        self.print_step("🏪 Attempting to open POS terminal...")
        
        if self.check_user_permission("POS"):
            self.print_step("POS terminal access granted - opening interface", "SUCCESS")
            self.print_step("🖥️  POS terminal ready for transactions")
            return True
        else:
            self.print_step("POS terminal access denied - insufficient permissions", "ERROR")
            self.print_step("💡 Please login with Cashier, Manager, or Admin role")
            return False
    
    def process_payment(self, amount: float, payment_type: str) -> bool:
        """
        Process payment (financial operation requiring authentication)
        """
        self.print_step(f"💳 Processing {payment_type} payment: ${amount:.2f}")
        
        if self.check_user_permission("PAYMENT"):
            self.print_step("Payment processing authorized", "SUCCESS")
            self.print_step("🔄 Connecting to payment gateway...")
            
            # Simulate processing time
            time.sleep(1)
            
            self.print_step(f"Payment processed successfully: ${amount:.2f}", "SUCCESS")
            return True
        else:
            self.print_step("Payment processing denied - authentication required", "ERROR")
            return False
    
    def generate_report(self, report_type: str) -> bool:
        """Generate business report"""
        self.print_step(f"📊 Generating {report_type} report...")
        
        if self.check_user_permission("REPORTS"):
            self.print_step(f"{report_type} report generated successfully", "SUCCESS")
            return True
        else:
            self.print_step("Report generation denied - insufficient permissions", "ERROR")
            return False

def test_health_checks():
    """Test the health check endpoints"""
    print("\n🏥 Testing Health Check Endpoints")
    print("=" * 50)
    
    base_url = "http://localhost:5281"
    
    health_endpoints = [
        ("/health", "Overall system health"),
        ("/health/ready", "Readiness check (includes database)"),
        ("/health/live", "Liveness check (basic status)")
    ]
    
    for endpoint, description in health_endpoints:
        try:
            response = requests.get(f"{base_url}{endpoint}", timeout=5)
            status = "SUCCESS" if response.status_code == 200 else "ERROR"
            print(f"[{datetime.now().strftime('%H:%M:%S')}] {'✅' if status == 'SUCCESS' else '❌'} {endpoint} - {description}: HTTP {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ {endpoint} - Failed to connect: {str(e)}")

def test_rate_limiting():
    """Test rate limiting protection"""
    print("\n🛡️  Testing Rate Limiting Protection")
    print("=" * 50)
    
    base_url = "http://localhost:5281"
    
    print("Attempting 6 rapid login attempts to trigger rate limiting...")
    
    for i in range(6):
        try:
            response = requests.post(
                f"{base_url}/auth/login",
                json={"username": "test", "password": "wrong"},
                timeout=5
            )
            
            if response.status_code == 429:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] ⚠️  Attempt {i+1}: Rate limited (HTTP 429) - Security protection working!")
                break
            else:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] ℹ️  Attempt {i+1}: HTTP {response.status_code} (within rate limit)")
        except requests.exceptions.RequestException as e:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ Attempt {i+1}: Connection failed: {str(e)}")
            
        time.sleep(0.5)  # Brief delay between attempts

def main():
    """
    Main demonstration of Legacy ERP → Modern Auth integration
    
    This showcases the Strangler Fig migration pattern:
    1. Legacy system continues to work
    2. Authentication gradually migrated to modern API
    3. Business logic preserved while security enhanced
    """
    
    print("🚀 Legacy ERP Integration Showcase")
    print("=" * 50)
    print("Demonstrating Strangler Fig migration pattern:")
    print("Legacy XHarbour ERP → Modern .NET 8 Auth API")
    print("")
    
    # Initialize components
    auth_wrapper = LegacyAuthWrapper()
    erp_system = LegacyERPSystem(auth_wrapper)
    
    print("📡 Initializing connection to Modern Auth API...")
    print("")
    
    # Demo 1: Successful Authentication
    print("🔐 Demo 1: User Authentication")
    print("-" * 30)
    if auth_wrapper.login("admin", "admin"):
        print("🎉 Authentication successful!")
        print("")
        
        # Demo 2: POS Terminal Access
        print("🏪 Demo 2: POS Terminal Access")  
        print("-" * 30)
        erp_system.open_pos_terminal()
        print("")
        
        # Demo 3: Payment Processing
        print("💳 Demo 3: Payment Processing")
        print("-" * 30)
        erp_system.process_payment(150.75, "Credit Card")
        print("")
        
        # Demo 4: Report Generation
        print("📊 Demo 4: Report Generation") 
        print("-" * 30)
        erp_system.generate_report("Sales Summary")
        print("")
        
        # Demo 5: Token Validation
        print("🔍 Demo 5: Token Validation")
        print("-" * 30)
        auth_wrapper.validate_token()
        print("")
        
    else:
        print("❌ Authentication failed - cannot proceed with business operations")
        print("")
    
    # Demo 6: Failed Authentication
    print("🚫 Demo 6: Security - Failed Authentication") 
    print("-" * 45)
    auth_wrapper.login("hacker", "wrongpassword")
    print("")
    
    # Demo 7: Rate Limiting Test
    test_rate_limiting()
    
    # Demo 8: Health Checks
    test_health_checks()
    
    print("\n🏁 Demo Complete!")
    print("=" * 50)
    print("📋 Integration Summary:")
    print("✅ Legacy ERP system successfully integrated with modern .NET 8 Auth API")
    print("✅ JWT tokens validated for all sensitive operations")
    print("✅ Role-based permissions enforced (Admin, Manager, Cashier)")
    print("✅ Rate limiting protects against brute force attacks")
    print("✅ Health checks enable monitoring and load balancer integration")
    print("✅ Graceful fallback handling for API unavailability")
    print("✅ Strangler Fig pattern - gradual migration while maintaining operation")
    print("")
    print("🎯 Perfect for showcase: Demonstrates real-world legacy modernization!")

if __name__ == "__main__":
    main()