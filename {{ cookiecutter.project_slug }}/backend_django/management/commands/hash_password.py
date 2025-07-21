from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.hashers import (
    make_password,
    Argon2PasswordHasher,
    PBKDF2PasswordHasher,
    PBKDF2SHA1PasswordHasher,
    BCryptSHA256PasswordHasher
)
import getpass


class Command(BaseCommand):
    help = 'Hash a password using Django\'s password hashers'
    
    # Available hashers mapping
    HASHERS = {
        'argon2': Argon2PasswordHasher,
        'pbkdf2': PBKDF2PasswordHasher,
        'pbkdf2_sha1': PBKDF2SHA1PasswordHasher,
        'bcrypt': BCryptSHA256PasswordHasher,
    }
    
    def add_arguments(self, parser):
        parser.add_argument('passw', type=str, nargs='?', help='Password to hash (optional, will prompt if not provided)')
        parser.add_argument(
            '--hash-type',
            type=str,
            default='argon2',
            choices=list(self.HASHERS.keys()),
            help='Hash algorithm to use (default: argon2)'
        )
    
    def handle(self, *args, **options):
        password = options['passw']
        hash_type = options['hash_type']
        
        # If no password provided, ask interactively
        if not password:
            password = getpass.getpass("Password to generate the hash for: ")
            if not password:
                raise CommandError("Password cannot be empty")
            
            # In interactive mode, also ask for hash type unless explicitly provided via --hash-type
            import sys
            hash_type_provided = any(arg.startswith('--hash-type') for arg in sys.argv)
            
            if not hash_type_provided:
                available_types = ', '.join(self.HASHERS.keys())
                hash_input = input(f"Hash type ({available_types}) [default: argon2]: ").strip()
                
                if hash_input:
                    if hash_input in self.HASHERS:
                        hash_type = hash_input
                    else:
                        raise CommandError(f"Invalid hash type '{hash_input}'. Choose from: {available_types}")
                # If nothing entered, keep the default 'argon2'
        
        try:
            # Get the specific hasher class
            hasher_class = self.HASHERS[hash_type]
            hasher = hasher_class()
            
            # Hash the password using the specific hasher
            hashed_password = hasher.encode(password, hasher.salt())
            
            print(f"Hash type: {hash_type}")
            print(f"Hashed password: {hashed_password}")
            
        except Exception as e:
            raise CommandError(f"Error hashing password: {e}")
