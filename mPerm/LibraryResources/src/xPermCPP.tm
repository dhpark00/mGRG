/* 2020.12.10(xPermML)  by dhpark */
/* 2025.09.06(xPermCPP) by dhpark */
/* 2025.10.02(xPermCPP) by dhpark */
/**********************************************************************
 * xPermCPP.tm to link the xPermCPP.cpp code                          *
 **********************************************************************/

#include "mathlink.h"
#include <cstdlib>

/**********************************************************************
 *                            PACKAGE                                 *
 **********************************************************************/

/* std::max, std::min with windows max, min */
#ifdef max

#undef max
#undef min

#endif

#include "xPermCPP.cpp"

static void gs2arr(int *arr, const gs_t& GS, size_t n) {
    for (size_t i = 0; i < GS.size(); ++i)
        for (size_t j = 0; j < n; ++j)
            arr[i*n + j] = GS[i][j];
}

static void arr2gs(gs_t& GS, int *arr, size_t n) {
    for (size_t i = 0; i < GS.size(); ++i)
        for (size_t j = 0; j < n; ++j)
            GS[i][j] = arr[i*n + j];
}

/**********************************************************************
 *                           INTERFACE                                *
 **********************************************************************/

/**********************************************************************/
:Begin:
:Function:      ML_canonical_perm
:Pattern:       mPerm`Private`MLCanonicalPerm[ mPerm`Private`perm_List,
                                               mPerm`Private`n_Integer,
                                               mPerm`Private`base_List,
                                               mPerm`Private`GS_List,
                                               mPerm`Private`freeps_List,
                                               mPerm`Private`vds_List,
                                               mPerm`Private`dummies_List,
                                               mPerm`Private`mQ_List,
                                               mPerm`Private`vrs_List,
                                               mPerm`Private`repes_List ]
:Arguments:     { mPerm`Private`perm,
                  mPerm`Private`n,
                  mPerm`Private`base,
                  mPerm`Private`GS,
                  mPerm`Private`freeps,
                  mPerm`Private`vds,
                  mPerm`Private`dummies,
                  mPerm`Private`mQ,
                  mPerm`Private`vrs,
                  mPerm`Private`repes }
:ArgumentTypes: { IntegerList,
                  Integer,
                  IntegerList,
                  IntegerList,
                  IntegerList,
                  IntegerList,
                  IntegerList,
                  IntegerList,
                  IntegerList,
                  IntegerList }
:ReturnType:    Manual
:End:

:Evaluate:

void ML_canonical_perm(int *arrPERM,    long p_n,
                       int n,
                       int *arrBase,    long b_n,
                       int *arrGS,      long mn,
                       int *arrFreeps,  long f_n,
                       int *arrVds,     long vds_n,
                       int *arrDummies, long d_n,
                       int *mQ,         long mQ_n,
                       int *arrVrs,     long vrs_n,
                       int *arrRepes,   long r_n)
{
    perm_t PERM(arrPERM, arrPERM + p_n);
    vec_t  base(arrBase, arrBase + b_n);
    gs_t   GS(mn/n, vec_t(n)); arr2gs(GS, arrGS, n);
    vec_t  freeps(arrFreeps, arrFreeps + f_n);
    vec_t  vds(arrVds, arrVds + vds_n);
    vec_t  dummies(arrDummies, arrDummies + d_n);
    vec_t  vrs(arrVrs, arrVrs + vrs_n);
    vec_t  repes(arrRepes, arrRepes + r_n);
    perm_t cr_perm{canonical_perm_ext(PERM, n, base, GS,
                                      freeps, vds, dummies, mQ, vrs, repes)};

    int *cperm = (int *) malloc(n*sizeof(int));

        for (size_t i = 0; i < cr_perm.size(); ++i)
            cperm[i] = cr_perm[i];

        int error = MLError(stdlink);
        if (error) {
            MLPutFunction(stdlink, "Print", 1);
            MLPutString(stdlink, MLErrorMessage(stdlink));
        }
        else
            MLPutIntegerList(stdlink, cperm, n);

    free(cperm);
    return;
}

/**********************************************************************/
:Begin:
:Function:      ML_MakePermGroup
:Pattern:       mPerm`Private`MLMakePermGroup[ mPerm`Private`arr_List,
                                               mPerm`Private`n_Integer ]
:Arguments:     {mPerm`Private`arr, mPerm`Private`n}
:ArgumentTypes: {IntegerList, Integer}
:ReturnType:    Manual
:End:

:Evaluate:

void ML_MakePermGroup(int *arrGS, long mn, int n) {
    gs_t GS(mn/n, vec_t(n)); arr2gs(GS, arrGS, n);

    gs_t group;
    make_perm_group(group, GS, n);
    size_t order = group.size();

    int *gr = (int *) malloc(order*n*sizeof(int));

        gs2arr(gr, group, n);
        MLPutIntegerList(stdlink, gr, order*n);

    free(gr);

    return;
}

/**********************************************************************/

/**********************************************************************
 *                            COMPATIBILITY                           *
 **********************************************************************/

#if MACINTOSH_MATHLINK

int main( int argc, char* argv[])
{
    /* Due to a bug in some standard C libraries that have shipped with
     * MPW, zero is passed to MLMain below.  (If you build this program
     * as an MPW tool, you can change the zero to argc.)
     */
    argc = argc; /* suppress warning */
    return MLMain( 0, argv);
}

#elif WINDOWS_MATHLINK

int PASCAL WinMain( HINSTANCE hinstCurrent, HINSTANCE hinstPrevious, LPSTR lpszCmdLine, int nCmdShow)
{
    char  buff[512];
    char FAR * buff_start = buff;
    char FAR * argv[32];
    char FAR * FAR * argv_end = argv + 32;

    hinstPrevious = hinstPrevious; /* suppress warning */

    if( !MLInitializeIcon( hinstCurrent, nCmdShow)) return 1;
    MLScanString( argv, &argv_end, &lpszCmdLine, &buff_start);
    return MLMain( argv_end - argv, argv);
}

#else

int main(int argc, char* argv[])
{
    return MLMain(argc, argv);
}

#endif
