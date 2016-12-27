#include<iostream>
#include<vector>
using namespace std;
typedef long long ll;

///////////////////////////////////////////////////////////////////////////////
// returns leftmost integer <= r for which less_than_target is false
template<typename T>
ll bin_search(bool (*less_than_target)(ll cur, T target), T target, ll r){
    T l = 0;
    T c = (l+r)/2;
    while(l<r){
        c = (l+r)/2;
        if(less_than_target(c, target)){
            if(l==c){
                c = r;
                l = r;
            }else l=c;
        }else r=c;
    }
    return c;
}
////////////////////////////////////////////////////////////////////////////////

// fnd operation (with path compression)
long fnd(vector<long>& par, long x){
    if(par[x]==-1)return x;
    else{
        par[x] = fnd(par, par[x]); // path compression
        return par[x];
    }
}

// combine operation (with rnk)
void combine(vector<long>& par, vector<long>& rnk, long x, long y){
    long xRoot = fnd(par, x);
    long yRoot = fnd(par, y);
    if(xRoot == yRoot)return;
    if(rnk[xRoot] < rnk[yRoot]){
        par[xRoot] = yRoot;
    }else if(rnk[yRoot] < rnk[xRoot]){
        par[yRoot] = xRoot;
    }else{
        if(xRoot < yRoot){
            par[yRoot] = xRoot;
            rnk[xRoot]++;
        }else{
            par[xRoot] = yRoot;
            rnk[yRoot]++;
        }
    }
}

// assign components to a graph with n vertices and edges specified by lhs->rhs
vector<long> assign_cpts(long n, const vector<long>& lhs, const vector<long>& rhs){
    vector<long> parent(n, -1);
    vector<long> rnk(n, 0);
    vector<long> cpts(n);

    for(long i=0; i<lhs.size(); i++)combine(parent, rnk, lhs[i], rhs[i]);
    for(long i=0; i<n; i++)cpts[i] = fnd(parent, i);

    return cpts;
}


////////////////////////////////////////////////////////////////////////////////
