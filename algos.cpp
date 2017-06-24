#include<iostream>
#include<vector>
using namespace std;
typedef long long ll;

///////////////////////////////////////////////////////////////////////////////
// compute all primes up to n
vector<ll> primes(ll n){
    ll nprimes = 0;
    vector<bool> prime(n+1);
    prime[0]=false;
    prime[1]=false;
    for (ll i=2;i<=n;i++){
        prime[i]=true;
    }
    for (ll i=2;i<=sqrt(n);i++){
        if (prime[i]){
            nprimes++;
            for (ll j=i+i;j<=n;j+=i){
                prime[j]=false;
            }
        }
    }

    vector<ll> prim(nprimes);
    ll idx = 0;
    for (ll i=2;i<=n;i++){
        if (prime[i]) prim[idx++]=i;
    }
    return(prim);
}
///////////////////////////////////////////////////////////////////////////////




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

// longest palindromic subsequence
int long_pal_subsequence(const vector<long>& v)
{
    int n = v.size();
    int L[n][n]; 
    for(int i = 0; i < n; i++)L[i][i] = 1;

    for(int lng = 2; lng <= n; lng++){
        for(int i=0; i<n-lng+1; i++){
            int j = i+lng-1;
            if(v[i]==v[j] && lng == 2)
                L[i][j] = 2;
            else if (v[i] == v[j])
                L[i][j] = L[i+1][j-1] + 2;
            else
                L[i][j] = max(L[i][j-1], L[i+1][j]);
        }
    } 
    return L[0][n-1];
}