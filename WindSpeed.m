classdef WindSpeed
    %an object oriented approach is used in this implementation
    %The code is based on Matlab2015b
    
    properties       
        sigma =0;
        centroids =[];
        weights =[];
        
    end
    properties(Constant)
        smse =0.00001;
        max_itr=1000
    end
    methods
        function ws =WindSpeed()
            load wind %Load data
            wdata = wind(:,4:15);
            year = wind(:,1);
            month = wind(:,2);
            day = wind(:,3);
            
            input_wdata = [wdata(:,1:4), wdata(:,6:12)];
            output_wdata = wdata(:,5);
            
            %Construct training and testing data
            %Determine the length from 1961 to 1970 to filter where the
            %training set will come from and the remaining is test set
            [l,~] =size(wind(ismember(wind(:,1),61:70),:));
            training_data = [input_wdata(1:l,:), output_wdata(1:l,:)];
            test_data = [input_wdata(l+1:end,:), output_wdata(l+1:end,:)];
            
            %Training and prediction
            rbf = ws.train(training_data,test_data);
            ws.sigma =rbf.sigma;
            ws.weights =rbf.w;
            ws.centroids=rbf.centroids;
        end      
    end
    
    methods(Static)
        function centroids =centers(data,k)
            
            %Computer the centroids from data points using kmeans       
            [~,centroids] = kmeans(data,k,'MaxIter',100000,'Replicates',10);           
        end
        
        function rbf = train(training_data,test_data)

            %training data and desired outputs
            tn_input =training_data(:,1:11);
            tn_ouput =training_data(:,12);
            
            %Test data with desired outputs
            test_input =test_data(:,1:11);
            test_output =test_data(:,12);
            
            k=300; %Estimated number of centers
            eta =0.0065; %learnign rate
            centroids = WindSpeed.centers(tn_input,k); %return the centers
            [l, ~] =size(training_data);
          
            
            %return matrix of distances between centers            
            d= pdist2(centroids,centroids,'euclidean','Largest',[]); 
            sigma = max(d(:))/sqrt(2*k); %Sigma
            
            
            %plots
            figure('position', [100,50,1024, 800])  ;
            %Error plots
            training_error = subplot(2,2,1);
            tn_plot = animatedline('Color','r');
            ts_plot = animatedline('Color','b');
            xlabel(training_error,'Iterations');
            ylabel(training_error,'MSE');
            %set(gca,'xscale','log');
            %set(gca,'yscale','log');
            %grid on;
            
            errP = subplot(2,2,2);
            ylabel(errP,'Y');
            xlabel(errP,'Data points');
            set(gca,'xscale','log');
                 
            
            %Acuracy plots
            accuracy = subplot(2,2,[3 4]);

           
            w = [1,.5-rand(1,k)];%Weights 
            itr=0;
            mse=Inf;
            count =0; %Stopping critera
            while mse>WindSpeed.smse && itr<WindSpeed.max_itr
                
                sse =0;
                %training
                for i =1:l
                    input = tn_input(i,:);
                    X = pdist2(centroids,input,'euclidean');
                    y= [1; exp(-(X.^2)./(2*sigma^2))];
                    output = w*y;
                    d_out=tn_ouput(i);
                    err= d_out-output;
                    sse =sse+err^2;
                    delta = eta*err.*[y';y';y';y'];
                    w=w+delta;
                end
                itr=itr+1;
                
                addpoints(tn_plot,(itr), (sse/l));hold on;
                title(training_error ,{'Learning curve',['Iterations: ' num2str(itr),...
                    ' ,Training MSE: ',num2str(sse/l),', Clusters: ',num2str(k)]}); drawnow;
                
                %For every 5 iterations, test the error perfomance of test
                %data
                if itr==1|| mod(itr,5) ==0
                    
                    [lt, ~]=size(test_input);
                    %Test data
                    predicated = WindSpeed.predict(test_input,sigma,centroids,w);
                   
                    Err = test_output-predicated;
                    t_sse = sum((Err).^2);
                    
                    %plot training error
                    addpoints(ts_plot,(itr), (t_sse/lt));hold on; drawnow
                    legend(training_error ,[tn_plot,ts_plot],{'Training','Test'},'Location','best');
                    
                    %Error plot
                    subplot(errP);hold off;
                    stem(errP,Err,'Marker','.','MarkerSize',8);
                    title(errP,{'Test Data: ERROR',['Iterations: ' num2str(itr),', MSE: ',...
                        num2str(t_sse/lt),', Clusters = ',num2str(k)]});
                    xlabel(errP,'Days (1971-1978)');drawnow;
                    
                    %Plot actual vs predicated
                    subplot(accuracy); hold off;
                    ac=plot(accuracy,test_output,'Color','r'); hold on
                    pd=plot(accuracy,predicated,'Color','b');
                    legend(accuracy ,[ac,pd],{'Actual','RBF Prediction'},'Location','best');
                    title(accuracy ,{['Test Data: Actual vs RBF Prediction ',...
                        ' Cluster = ',num2str(k) ],['Iterations: ' num2str(itr),...
                        ', MSE: ',num2str(t_sse/lt)]});
                    ylabel(accuracy,'Wind Speed');
                    xlabel(accuracy,'Days (1971-1978)');drawnow;
                end
                if abs((sse/l)-mse)< 1e-4
                  count =count+1;
                  if count >10
                      break;
                  end
                end
                mse =sse/l;
            end
            rbf.w=w;
            rbf.sigma=sigma;
            rbf.centroids=centroids;
        end
        function output = predict(data,sigma,centroids,w)
            %predict the wind spead at station given the data, sigma,
            %centers and weights
            [L,~]=size(data);
            output =zeros(L,1);
            for i =1:L
                input = data(i,:);
                X = pdist2(centroids,input,'euclidean');
                y= [1; exp(-(X.^2)./(2*sigma^2))];
                output(i)= w*y;                
            end
            
        end
    end
    
end
