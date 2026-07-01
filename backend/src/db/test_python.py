import ssl
import pymysql
import sys

print(f"Python {sys.version}")
print(f"OpenSSL: {ssl.OPENSSL_VERSION}")
print()

HOST = "gateway01.us-east-1.prod.aws.tidbcloud.com"
PORT = 4000
USER = "3XCNBfWUvxfEhKC.root"
PASS = "fEge8yTXgwHoOKmv"
DB   = "liba_db"

configs = [
    ("1. SSL con verify=False", dict(ssl={'ca': None}, ssl_verify_cert=False, ssl_verify_identity=False)),
    ("2. SSL con verify=True",  dict(ssl={}, ssl_verify_cert=True, ssl_verify_identity=False)),
    ("3. Sin SSL",              dict()),
]

for label, kwargs in configs:
    print(f"Probando {label} ...", end=" ", flush=True)
    try:
        conn = pymysql.connect(
            host=HOST, port=PORT, user=USER, password=PASS, db=DB,
            connect_timeout=10,
            **kwargs
        )
        cur = conn.cursor()
        cur.execute("SELECT 1 AS ok, DATABASE() AS db, VERSION() AS ver")
        row = cur.fetchone()
        conn.close()
        print(f"CONECTADO -> ok={row[0]}, db={row[1]}, ver={row[2]}")
        break
    except Exception as e:
        print(f"FALLO: {type(e).__name__}: {e}")
