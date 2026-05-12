import sqlite3
conn = sqlite3.connect('/opt/easyorders-api/data/easyorders.db')
cur = conn.cursor()
cur.execute('DELETE FROM orders')
cur.execute("DELETE FROM sqlite_sequence WHERE name='orders'")
conn.commit()
print(cur.execute('SELECT count(*) FROM orders').fetchone()[0])
conn.close()
