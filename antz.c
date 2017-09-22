#include<stdio.h>
#include<graphics.h>
#include<dos.h>
#include<stdlib.h>

#define TIME 1000
#define LENGTH 22

typedef struct _ANT
{
	int x1, y1, x2, y2, d, l, index, color, status;
	int *path;
} ANT;

/*
 *    Purpose   : For simulating movement of ants.
 *    Arguments : [n] is number of ants in simulation.
 *    Returns   : None.
 *    PreReqs   : None.
 *    Caution   : Naturality in ants' movements are preserved iff the function is left unchanged.
 *    TestSpeed : None.
 */
void antz(int n)
{
	int delta[]={-1, 0, 1, 0, 0, -1, 0, 1, -1, -1, -1, 1, 1, -1, 1, 1};
	int i, j, _x1, _y1, alive=n, time=TIME/alive;

	/** code for initialisation of every ant **/
	ANT *ants=(ANT *)malloc(sizeof(ANT)*n);                     /* array of n ant structures */
	for(i=0; i<n; i++)
	{
		ants[i].x1=random(640), ants[i].y1=random(480);       /* every ant starts at a fixed random point */
		ants[i].x2=random(640), ants[i].y2=random(480);       /* every ant stops at a fixed random point */
		ants[i].d=0, ants[i].l=0;
		ants[i].index=0, ants[i].status=1;
		ants[i].color=random(15)+1;					/* values set here have a meaning. they arent random */
		ants[i].path=(int *)malloc(sizeof(int)*LENGTH*2);     /* path[] maintains ant length by cleanin up crap */
		for(j=0; j<LENGTH*2; j++) ants[i].path[j]=-1;         /* path[*] initially set to -1 for a reason */
		/*circle(ants[i].x1, ants[i].y1, 5);*/
		/*circle(ants[i].x2, ants[i].y2, 5);*/
	}

	while(1010)
	{
		for(i=0; i<n && !ants[i].status; i++);                /* checks if ants are dead or alive */
		if(i==n) break;                                       /* if all ants are dead break out of loop */

		for(i=0; i<n; i++)                                    /* every ant moves one pixel at a time with TIME delay */
		{
			if(ants[i].status)                              /* make sure we move an ant which is alive */
			{
				if(!ants[i].l)                            /* if ant travels random length in random direction.. */
					ants[i].l=random(100), ants[i].d=random(8), i--;      /* ..now is the time to take new randon direction & length */
				else  						/* yet to complete random length of path in a random direction */
				{
					/* coordinates of the next pixel for every ant */
					_x1=ants[i].x1+delta[2*ants[i].d];
					_y1=ants[i].y1+delta[2*ants[i].d+1];

					if(_x1>=0 && _x1<=639 && _y1>=0 && _y1<=479)    /* if the new coordinates make a valid point */
					{
						/* length of ant stays constant iff crawling a new pixel is balanced by wiping out last pixel */
						if(ants[i].path[2*ants[i].index]!=-1 && ants[i].path[2*ants[i].index+1]!=-1)
						      putpixel(ants[i].path[2*ants[i].index], ants[i].path[2*ants[i].index+1], 0);

						/* new pixel becomes old eventually, so remember it in order to wipe it out later */
						ants[i].path[2*ants[i].index]=ants[i].x1=_x1;
						ants[i].path[2*ants[i].index+1]=ants[i].y1=_y1;

						/* every ant advances one pixel at a time waiting for "time" delay */
						putpixel(_x1, _y1, ants[i].color++);
						delay(time);

						/* if ant reaches its destination, wipeout entire length in one step without delay*/
						if(_x1==ants[i].x2 && _y1==ants[i].y2)
						{
							ants[i].index++;
							for(j=0; j<LENGTH; j++)
							{
								ants[i].index=(++ants[i].index)%LENGTH;
								putpixel(ants[i].path[2*ants[i].index], ants[i].path[2*ants[i].index+1], 0);
							}
							ants[i].status=0, time=1000/(--alive);    /* recalculate time delay */
						}
						else  /* ant hasnt reached its destination, it continues its journey */
							ants[i].index=(++ants[i].index)%LENGTH, ants[i].l--;
					}
					else  /* if next point isnt a valid point, cancel further length in random direction */
					      ants[i].l=0, i--;
				}
			}
		}
	}
      /* free memory previously allocated to path arrays */
	for(i=0; i<n; i++) free(ants[i].path);
}

/*
 *    for demonstration purpose only.
 */
int main(void)
{
	int gd=DETECT, gm;
	initgraph(&gd, &gm, "");

	antz(10);               /* change 10 to get the number of ants you want */

	closegraph();
	restorecrtmode();
	return 0;
}

