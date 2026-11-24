import argparse,json,sqlite3
p=argparse.ArgumentParser()
p.add_argument('table');p.add_argument('--side',choices=['client','server'],default='server');p.add_argument('--id');p.add_argument('--limit',type=int,default=10);p.add_argument('--db',default='/home/gamedev/darklord-dgi/catalog.sqlite')
a=p.parse_args()
db=sqlite3.connect('file:'+a.db+'?mode=ro',uri=True)
sql='SELECT id,data FROM records WHERE side=? AND name=?';args=[a.side,a.table]
if a.id is not None:sql+=' AND id=?';args.append(a.id)
sql+=' ORDER BY id LIMIT ?';args.append(max(1,min(a.limit,1000)))
print(json.dumps([{'id':i,'data':json.loads(d)} for i,d in db.execute(sql,args)],ensure_ascii=False,indent=2))
