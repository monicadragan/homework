/*Tema1 SO2: interceptarea apelurilor de sistem*/
/***********Autor: Monica Dragan****************/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/unistd.h>
#include <linux/slab.h>
#include <linux/list.h>
#include <linux/sched.h>
#include "sci_lin.h"

MODULE_DESCRIPTION("Tema1 SO2");
MODULE_AUTHOR("Monica Dragan");
MODULE_LICENSE("GPL");

#define LOG_LEVEL	KERN_ALERT
#define NO_SYSCALLS 	300

struct syscall_params{
	long ebx, ecx, edx, esi, edi, ebp, eax;
};

asmlinkage long (*_interceptor)(struct syscall_params);
asmlinkage void (*_removeTerinatedProcess)(struct syscall_params);
asmlinkage long (*_my_syscall)(int cmd, int syscall, int pid);

struct process {
	pid_t pid;
	int syscall;
	struct task_struct task;
	struct list_head list;
};

struct syscall_info{
	asmlinkage long (*f) (struct syscall_params);
	int intercepted;
};

extern void *sys_call_table[];
extern long my_nr_syscalls;

struct syscall_info original_sys_call_table[NO_SYSCALLS];

LIST_HEAD(process_list);
DEFINE_RWLOCK(lock);

/**
 * add_pid() - adauga o intrare in lista de procese
 * @syscall: numarul apelului de sistem
 * @pid: pid-ul procesului
 * @return: succes sau eroare
 **/
static int add_pid(int syscall, pid_t pid){

	struct process *ple = kmalloc(sizeof *ple, GFP_KERNEL);
	       
	if (!ple)
	        return -ENOMEM;
        ple->pid = pid;
        ple->syscall = syscall;
        INIT_LIST_HEAD(&ple->list);
        list_add(&ple->list, &process_list);

        return 0;
}

/**
 * del_pid() - sterge din lista de procese intrarea cu apelul de sistem
 * siscall si id-ul @pid
 * @syscall: numarul apelului de sistem
 * @pid: pid-ul procesului
 * @return: succes sau eroare
 **/

static int del_pid(int syscall, pid_t pid){

	struct list_head *i, *tmp;
	struct process *ple;

	list_for_each_safe(i, tmp, &process_list) {
		ple = list_entry(i, struct process, list);
		if (ple->pid == pid && ple->syscall == syscall) {
			list_del(i);
	        	kfree(ple);
			return 0;
		}
	}
	return -EINVAL;
}

/**
 *contains() - cauta in lista de procese procesul cu pid-ul @pid si syscall @syscall
 *@syscall: nuamrul apelului de sistem
 *@pid: pid-ul unui proces
 *@return: 1 pentru succes sau 0
 **/

static int contains(int syscall, pid_t pid){

	struct list_head *i, *tmp;
	struct process *ple;

	list_for_each_safe(i, tmp, &process_list) {
		ple = list_entry(i, struct process, list);
		if (ple->pid == pid && ple->syscall == syscall) 
			return 1;
	}
	return 0;
}


asmlinkage long interceptor(struct syscall_params sp){

	int syscall = sp.eax;

	int r = original_sys_call_table[syscall].f(sp);
	int pid = current->pid;

	int monitored = 0;
	struct list_head *cnt, *tmp;
	struct process *ple;

	list_for_each_safe(cnt, tmp, &process_list){
		ple = list_entry(cnt, struct process, list);
		if(ple->pid == pid && ple->syscall == syscall){
			monitored = 1;
			break;
		}
	}

	if(monitored){
		//pid, syscall, 6 argumente, val_return
		log_syscall(pid, syscall,sp.ebx, sp.ecx, sp.edx, sp.esi, sp.edi, sp.ebp, r);
	}

	return r;
}

asmlinkage long my_syscall(int cmd, int syscall, int pid){

	int monitor_busy = 0;
	struct list_head *cnt, *tmp;
	struct process *ple;

	list_for_each_safe(cnt, tmp, &process_list){
		ple = list_entry(cnt, struct process, list);
		if(ple->pid == pid && ple->syscall == syscall){
			monitor_busy = 1;
			break;
		}
	}

	if(syscall == __NR_exit_group || syscall == MY_SYSCALL_NO || syscall < 0){
		return -EINVAL;
	}

	else if(cmd == REQUEST_SYSCALL_INTERCEPT){

		//daca utilizatorul e privilegiat
		if(current->cred->uid == 0){
			if(original_sys_call_table[syscall].intercepted == 1){
				return -EBUSY;
			}

			//salvez rutina originala de tratare a syscall-ului
			write_lock(&lock);
			original_sys_call_table[syscall].f = (long*)sys_call_table[syscall];
			original_sys_call_table[syscall].intercepted = 1;
			sys_call_table[syscall] = (long*)interceptor;
			write_unlock(&lock);
		}
		else{
			return -EPERM;
		}	
	}

	else if(cmd == REQUEST_SYSCALL_RELEASE){
		if(current->cred->uid == 0){
			//restaurez rutina originala de tratare a syscall-ului
			if(original_sys_call_table[syscall].intercepted == 0){
				return -EINVAL;
			}
	
			write_lock(&lock);
			sys_call_table[syscall] = original_sys_call_table[syscall].f;
			write_unlock(&lock);

			original_sys_call_table[syscall].intercepted = 0;
		}
		else{
			return -EPERM;
		}	
	}

	else if(cmd == REQUEST_START_MONITOR){		

		if(original_sys_call_table[syscall].intercepted == 0)
			return -EINVAL;

		//daca pidul este valid
		//struct pid *task_pid = find_vpid(pid);
		if(pid < 0)
			return -EINVAL;
		
		//daca monitorul este busy
		if(monitor_busy == 1)
			return -EBUSY;

		//daca se doreste monitorizarea tutror proceselor
		if(pid == 0 && current->cred->uid != 0){
			return -EPERM;			
		}

		else if(current->cred->uid == 0)
			add_pid(syscall,pid);

		//utilizator neprivilegiat
		else if(current->cred->uid != 0){

			//verific daca procesul monitorizat este chiar
			//current sau unul dintre copiii lui current
			if(current->pid == pid){
				add_pid(syscall,pid);
			}
			else{			
				struct list_head *i;
				int ok = 0;			
			
				struct pid *pid_struct = find_get_pid(current->pid);
				struct task_struct *this_task = pid_task(pid_struct,PIDTYPE_PID);

				list_for_each(i, &(this_task->children)) {
    					struct task_struct *task = list_entry(i, struct task_struct, sibling);
				    	if (task->pid == pid) {
						ok = 1;
						break;
					}
				}
				if(ok == 0){
					return -EPERM;
				}
				//adaug procesul monitorizat in lista
				add_pid(syscall, pid);
			}						
		}
	}

	else if(cmd == REQUEST_STOP_MONITOR){

		if(current->cred->uid != 0 && pid == 0)
			return -EPERM;

		else if(current->cred->uid != 0 && pid != current->pid)
			return -EPERM;

		if(!contains(syscall,pid))
			return -EINVAL;

		del_pid(syscall,pid);
	}
	
	return 0;
}

asmlinkage void removeTerinatedProcess(struct syscall_params sp){

	//elimin procesul care s-au terminat
	del_pid(-1,current->pid);
}

static int my_init(void){

	int i;

	for(i=0;i<NO_SYSCALLS;i++){
		original_sys_call_table[i].intercepted = 0;
	}

	//suprascriu apelul de sistem 0
	sys_call_table[0] = (long*)my_syscall;

	//suprascriu apelul de sistem exit_group
	original_sys_call_table[__NR_exit_group].f = (long*)sys_call_table[__NR_exit_group];
        sys_call_table[__NR_exit_group] = (long*)removeTerinatedProcess;

	return 0;
}

static void my_exit(void){
	sys_call_table[__NR_exit_group] = original_sys_call_table[__NR_exit_group].f;
}

module_init(my_init);
module_exit(my_exit);
