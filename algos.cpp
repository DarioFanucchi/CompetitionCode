#include<iostream>
#include<vector>
using namespace std;


typedef long long ll;
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
