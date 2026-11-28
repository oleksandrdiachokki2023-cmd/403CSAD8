import vcdvcd, matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
v=vcdvcd.VCDVCD('sim/i2c.vcd')
def sig(name):
    return v['tb_i2c.'+name]
def tv(s): return [(t/1000.0, x) for t,x in s.tv]   # ns
def step(tvl,t0,t1):
    xs=[];ys=[]
    cur=None
    for t,x in tvl:
        if t<=t0: cur=x
    pts=[(t0,cur)]+[(t,x) for t,x in tvl if t0<t<=t1]
    for i,(t,x) in enumerate(pts):
        xs.append(t); ys.append(x)
    xs.append(t1); ys.append(pts[-1][1]); return xs,ys
def val(x):
    try: return int(x,2)
    except: return None
def draw(t0,t1,fn,title,sigs):
    fig,axs=plt.subplots(len(sigs),1,figsize=(12,1.0*len(sigs)+0.6),sharex=True)
    for ax,(label,name,kind) in zip(axs,sigs):
        tvl=tv(sig(name)); xs,ys=step(tvl,t0,t1)
        if kind=='bit':
            ax.step(xs,[1 if y=='1' else 0 for y in ys],where='post',color='#1f77b4',lw=1.4)
            ax.set_ylim(-0.3,1.3); ax.set_yticks([0,1])
        else:
            for i in range(len(xs)-1):
                n=val(ys[i]); 
                ax.plot([xs[i],xs[i+1]],[0.5,0.5],color='#2ca02c',lw=1.4)
                ax.axvline(xs[i],color='#2ca02c',lw=0.6,ymin=.2,ymax=.8)
                if xs[i+1]-xs[i]>(t1-t0)*0.03:
                    ax.text((xs[i]+xs[i+1])/2,0.62,(f"{n:#04x}" if kind=='hex' else str(n)),ha='center',fontsize=8)
            ax.set_ylim(0,1); ax.set_yticks([])
        ax.set_ylabel(label,rotation=0,ha='right',va='center',fontsize=9)
        ax.grid(True,alpha=.3)
    axs[-1].set_xlabel('t, нс'); axs[0].set_title(title,fontsize=11)
    plt.xlim(t0,t1); plt.tight_layout(); plt.savefig(fn,dpi=130); plt.close()
S=[('start','start','bit'),('SCL','scl','bit'),('SDA','sda','bit'),
   ('state Tx','dut.u_tx.state[2:0]','dec'),('addr_match','rx_match','bit'),('rx_valid','rx_valid','bit'),('rx_data','rx_data[7:0]','hex'),('ack_err','ack_err','bit'),('done','done','bit')]
import re
# transaction boundaries from start pulses
st=[t/1000 for t,x in sig('start').tv if x=='1']
print(st)
draw(st[0]-100,st[0]+6900,'img/wave1.png','Транзакція 1: запис 0xA5 за адресою 0x50 (ACK)',S)
draw(st[2]-100,st[2]+5000,'img/wave3.png','Транзакція 3: адреса 0x51 — NACK',S)
