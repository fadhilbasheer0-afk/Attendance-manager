const fs=require('fs');
const os=require('os');
const path=require('path');
const https=require('https');
const cfgPath=path.join(os.homedir(),'.config','configstore','firebase-tools.json');
const cfg=JSON.parse(fs.readFileSync(cfgPath,'utf8'));
const token=cfg.tokens?.access_token;
if(!token) throw new Error('No Firebase CLI access token found.');
const project='tuition-attendance-9a2b1';
const adminUid='ckTVltTA6VMRJrbkr7ZBR54yA5y1';
const collections=['institutions','branches','teachers','students','classes','attendance','institutionInvites','teacherInvites','appAdmins'];
function request(method,url,body){
  return new Promise((resolve,reject)=>{
    const data=body?JSON.stringify(body):null;
    const u=new URL(url);
    const opts={method,headers:{Authorization:`Bearer ${token}`, 'Content-Type':'application/json'}};
    if(data) opts.headers['Content-Length']=Buffer.byteLength(data);
    const req=https.request(u,opts,res=>{
      let buf='';
      res.on('data',chunk=>buf+=chunk);
      res.on('end',()=>{
        if(res.statusCode>=200 && res.statusCode<300){
          resolve(buf?JSON.parse(buf):null);
        } else {
          const err=new Error(`HTTP ${res.statusCode}: ${buf}`);
          err.code=res.statusCode;
          reject(err);
        }
      });
    });
    req.on('error',reject);
    if(data) req.write(data);
    req.end();
  });
}
async function listCollection(col,pageToken){
  let url=`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/${col}`;
  const params=[];
  if(pageToken) params.push(`pageToken=${pageToken}`);
  if(params.length) url += `?${params.join('&')}`;
  return await request('GET',url);
}
async function deleteDoc(name){
  console.log(`Deleting ${name}`);
  return await request('DELETE',`https://firestore.googleapis.com/v1/${name}`);
}
async function createAdmin(){
  console.log(`Creating admin doc for ${adminUid}`);
  const url=`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/appAdmins?documentId=${adminUid}`;
  return await request('POST',url,{fields:{}});
}
async function deleteCollection(col){
  console.log(`Cleaning collection ${col}`);
  let pageToken;
  while(true){
    let res;
    try {
      res = await listCollection(col,pageToken);
    } catch(err){
      if(err.code===404){ console.log(`Collection ${col} does not exist or is empty.`); return; }
      throw err;
    }
    if(!res.documents || res.documents.length===0){
      return;
    }
    for(const doc of res.documents){
      await deleteDoc(doc.name);
    }
    pageToken = res.nextPageToken;
    if(!pageToken) return;
  }
}
(async()=>{
  for(const col of collections){
    await deleteCollection(col);
  }
  await createAdmin();
  console.log('Done.');
})();
