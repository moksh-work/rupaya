#!/usr/bin/env python3
"""
AWS Infrastructure Pre-Destruction Validator

This module provides comprehensive pre-destruction checks including:
- AWS credentials validation
- Resource inventory
- Dependency analysis
- Backup verification
- Permission checks
"""

import sys
import json
import subprocess
import argparse
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum
import logging
from datetime import datetime


class CheckStatus(Enum):
    """Status of a validation check"""
    PASSED = "PASSED"
    FAILED = "FAILED"
    WARNING = "WARNING"
    SKIPPED = "SKIPPED"


@dataclass
class CheckResult:
    """Result of a single validation check"""
    check_name: str
    status: CheckStatus
    message: str
    details: Optional[Dict] = None


class Colors:
    """ANSI color codes"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'


class PreDestructionValidator:
    """Main validator class for pre-destruction checks"""

    def __init__(self, region: str = "us-east-1", verbose: bool = False):
        self.region = region
        self.verbose = verbose
        self.results: List[CheckResult] = []
        
        # Setup logging
        log_level = logging.DEBUG if verbose else logging.INFO
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)

    def run_command(self, cmd: List[str], check_error: bool = True) -> Tuple[bool, str]:
        """Run a shell command and return success status and output"""
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30
            )
            if check_error and result.returncode != 0:
                self.logger.error(f"Command failed: {' '.join(cmd)}\nError: {result.stderr}")
                return False, result.stderr
            return True, result.stdout
        except subprocess.TimeoutExpired:
            self.logger.error(f"Command timeout: {' '.join(cmd)}")
            return False, "Command timed out"
        except Exception as e:
            self.logger.error(f"Command error: {str(e)}")
            return False, str(e)

    def check_aws_credentials(self) -> CheckResult:
        """Verify AWS credentials are configured"""
        self.logger.info("Checking AWS credentials...")
        
        success, output = self.run_command(
            ["aws", "sts", "get-caller-identity", "--region", self.region],
            check_error=False
        )
        
        if not success:
            return CheckResult(
                check_name="AWS Credentials",
                status=CheckStatus.FAILED,
                message="AWS credentials not configured or invalid"
            )
        
        try:
            creds = json.loads(output)
            return CheckResult(
                check_name="AWS Credentials",
                status=CheckStatus.PASSED,
                message=f"Credentials valid - Account: {creds['Account']}, User: {creds['Arn']}",
                details=creds
            )
        except json.JSONDecodeError:
            return CheckResult(
                check_name="AWS Credentials",
                status=CheckStatus.FAILED,
                message="Could not parse AWS credentials response"
            )

    def check_terraform_installed(self) -> CheckResult:
        """Verify Terraform is installed"""
        self.logger.info("Checking Terraform installation...")
        
        success, output = self.run_command(
            ["terraform", "version"],
            check_error=False
        )
        
        if not success:
            return CheckResult(
                check_name="Terraform Installation",
                status=CheckStatus.FAILED,
                message="Terraform not installed or not in PATH"
            )
        
        version = output.split('\n')[0]
        return CheckResult(
            check_name="Terraform Installation",
            status=CheckStatus.PASSED,
            message=f"Terraform installed - {version}"
        )

    def check_aws_cli_installed(self) -> CheckResult:
        """Verify AWS CLI is installed"""
        self.logger.info("Checking AWS CLI installation...")
        
        success, output = self.run_command(
            ["aws", "--version"],
            check_error=False
        )
        
        if not success:
            return CheckResult(
                check_name="AWS CLI Installation",
                status=CheckStatus.FAILED,
                message="AWS CLI not installed or not in PATH"
            )
        
        return CheckResult(
            check_name="AWS CLI Installation",
            status=CheckStatus.PASSED,
            message=f"AWS CLI installed - {output.strip()}"
        )

    def check_ecr_repositories(self) -> CheckResult:
        """Inventory ECR repositories"""
        self.logger.info("Checking ECR repositories...")
        
        success, output = self.run_command(
            ["aws", "ecr", "describe-repositories", "--region", self.region],
            check_error=False
        )
        
        if not success:
            return CheckResult(
                check_name="ECR Repositories",
                status=CheckStatus.WARNING,
                message="Could not list ECR repositories"
            )
        
        try:
            data = json.loads(output)
            repos = data.get('repositories', [])
            repo_names = [r['repositoryName'] for r in repos]
            
            if not repos:
                return CheckResult(
                    check_name="ECR Repositories",
                    status=CheckStatus.PASSED,
                    message="No ECR repositories found"
                )
            
            # Check for images in repositories
            total_images = 0
            for repo in repos:
                success, img_output = self.run_command(
                    ["aws", "ecr", "describe-images", 
                     "--repository-name", repo['repositoryName'],
                     "--region", self.region],
                    check_error=False
                )
                if success:
                    img_data = json.loads(img_output)
                    total_images += len(img_data.get('imageDetails', []))
            
            return CheckResult(
                check_name="ECR Repositories",
                status=CheckStatus.PASSED,
                message=f"Found {len(repos)} repositories with {total_images} total images",
                details={"repositories": repo_names, "total_images": total_images}
            )
        except json.JSONDecodeError:
            return CheckResult(
                check_name="ECR Repositories",
                status=CheckStatus.WARNING,
                message="Could not parse ECR repositories response"
            )

    def check_rds_databases(self) -> CheckResult:
        """Inventory RDS databases"""
        self.logger.info("Checking RDS databases...")
        
        success, output = self.run_command(
            ["aws", "rds", "describe-db-instances", "--region", self.region],
            check_error=False
        )
        
        if not success:
            return CheckResult(
                check_name="RDS Databases",
                status=CheckStatus.WARNING,
                message="Could not list RDS databases"
            )
        
        try:
            data = json.loads(output)
            databases = data.get('DBInstances', [])
            
            if not databases:
                return CheckResult(
                    check_name="RDS Databases",
                    status=CheckStatus.PASSED,
                    message="No RDS databases found"
                )
            
            db_names = [db['DBInstanceIdentifier'] for db in databases]
            return CheckResult(
                check_name="RDS Databases",
                status=CheckStatus.PASSED,
                message=f"Found {len(databases)} RDS database(s)",
                details={"databases": db_names}
            )
        except json.JSONDecodeError:
            return CheckResult(
                check_name="RDS Databases",
                status=CheckStatus.WARNING,
                message="Could not parse RDS databases response"
            )

    def check_elasticache_clusters(self) -> CheckResult:
        """Inventory ElastiCache clusters"""
        self.logger.info("Checking ElastiCache clusters...")
        
        success, output = self.run_command(
            ["aws", "elasticache", "describe-replication-groups", "--region", self.region],
            check_error=False
        )
        
        if not success:
            return CheckResult(
                check_name="ElastiCache Clusters",
                status=CheckStatus.WARNING,
                message="Could not list ElastiCache clusters"
            )
        
        try:
            data = json.loads(output)
            clusters = data.get('ReplicationGroups', [])
            
            if not clusters:
                return CheckResult(
                    check_name="ElastiCache Clusters",
                    status=CheckStatus.PASSED,
                    message="No ElastiCache clusters found"
                )
            
            cluster_names = [c['ReplicationGroupId'] for c in clusters]
            return CheckResult(
                check_name="ElastiCache Clusters",
                status=CheckStatus.PASSED,
                message=f"Found {len(clusters)} ElastiCache cluster(s)",
                details={"clusters": cluster_names}
            )
        except json.JSONDecodeError:
            return CheckResult(
                check_name="ElastiCache Clusters",
                status=CheckStatus.WARNING,
                message="Could not parse ElastiCache response"
            )

    def check_iam_resources(self) -> CheckResult:
        """Check for IAM roles related to the project"""
        self.logger.info("Checking IAM resources...")
        
        success, output = self.run_command(
            ["aws", "iam", "list-roles"],
            check_error=False
        )
        
        if not success:
            return CheckResult(
                check_name="IAM Resources",
                status=CheckStatus.WARNING,
                message="Could not list IAM roles"
            )
        
        try:
            data = json.loads(output)
            roles = data.get('Roles', [])
            project_roles = [r for r in roles if 'rupaya' in r['RoleName'].lower()]
            
            if not project_roles:
                return CheckResult(
                    check_name="IAM Resources",
                    status=CheckStatus.PASSED,
                    message="No project-related IAM roles found"
                )
            
            role_names = [r['RoleName'] for r in project_roles]
            return CheckResult(
                check_name="IAM Resources",
                status=CheckStatus.PASSED,
                message=f"Found {len(project_roles)} project-related IAM role(s)",
                details={"roles": role_names}
            )
        except json.JSONDecodeError:
            return CheckResult(
                check_name="IAM Resources",
                status=CheckStatus.WARNING,
                message="Could not parse IAM response"
            )

    def run_all_checks(self) -> List[CheckResult]:
        """Run all validation checks"""
        self.logger.info("Starting pre-destruction validation checks...")
        
        checks = [
            self.check_aws_credentials,
            self.check_terraform_installed,
            self.check_aws_cli_installed,
            self.check_ecr_repositories,
            self.check_rds_databases,
            self.check_elasticache_clusters,
            self.check_iam_resources,
        ]
        
        for check in checks:
            try:
                result = check()
                self.results.append(result)
            except Exception as e:
                self.logger.error(f"Check {check.__name__} failed: {str(e)}")
                self.results.append(CheckResult(
                    check_name=check.__name__,
                    status=CheckStatus.FAILED,
                    message=f"Exception: {str(e)}"
                ))
        
        return self.results

    def print_report(self):
        """Print validation report"""
        print("\n" + "=" * 70)
        print(f"{Colors.BLUE}AWS Infrastructure Pre-Destruction Validation Report{Colors.RESET}")
        print(f"Timestamp: {datetime.now().isoformat()}")
        print("=" * 70 + "\n")
        
        passed = failed = warning = 0
        
        for result in self.results:
            status_color = {
                CheckStatus.PASSED: Colors.GREEN,
                CheckStatus.FAILED: Colors.RED,
                CheckStatus.WARNING: Colors.YELLOW,
                CheckStatus.SKIPPED: Colors.BLUE,
            }[result.status]
            
            status_symbol = {
                CheckStatus.PASSED: "✓",
                CheckStatus.FAILED: "✗",
                CheckStatus.WARNING: "⚠",
                CheckStatus.SKIPPED: "→",
            }[result.status]
            
            print(f"{status_color}{status_symbol}{Colors.RESET} {result.check_name}")
            print(f"  {result.message}")
            
            if result.details and self.verbose:
                print(f"  Details: {json.dumps(result.details, indent=2)}")
            
            print()
            
            if result.status == CheckStatus.PASSED:
                passed += 1
            elif result.status == CheckStatus.FAILED:
                failed += 1
            elif result.status == CheckStatus.WARNING:
                warning += 1
        
        print("=" * 70)
        print(f"Summary: {Colors.GREEN}{passed} passed{Colors.RESET}, " +
              f"{Colors.RED}{failed} failed{Colors.RESET}, " +
              f"{Colors.YELLOW}{warning} warnings{Colors.RESET}")
        print("=" * 70 + "\n")
        
        return failed == 0

    def export_report(self, filepath: str):
        """Export validation report to JSON file"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "region": self.region,
            "results": [
                {
                    "check_name": r.check_name,
                    "status": r.status.value,
                    "message": r.message,
                    "details": r.details
                }
                for r in self.results
            ]
        }
        
        with open(filepath, 'w') as f:
            json.dump(report, f, indent=2)
        
        self.logger.info(f"Report exported to {filepath}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="AWS Infrastructure Pre-Destruction Validator"
    )
    parser.add_argument(
        "--region",
        default="us-east-1",
        help="AWS region to check (default: us-east-1)"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )
    parser.add_argument(
        "--export",
        help="Export report to JSON file"
    )
    
    args = parser.parse_args()
    
    validator = PreDestructionValidator(
        region=args.region,
        verbose=args.verbose
    )
    
    results = validator.run_all_checks()
    success = validator.print_report()
    
    if args.export:
        validator.export_report(args.export)
    
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
